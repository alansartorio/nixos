//! Stream a clockin project's session state and worked-time totals as JSON
//! lines for the eww bar to consume.
//!
//! Ported verbatim from a rust-script file, minus the unstable
//! `#![feature(exit_status_error)]` attribute, which was declared but unused
//! (the status checks here already go through `ExitStatus::success`).

use anyhow::{Context, Result, anyhow};
use async_process::{Command, Stdio};
use async_std::io;
use futures::{FutureExt, Stream, StreamExt};
use futures_lite::io::{AsyncBufReadExt, BufReader};
use serde::{Serialize, Serializer};
use std::time::{Duration, Instant};

fn get_hms(x: &Duration) -> (u64, u8, u8) {
    let mut secs = x.as_secs();
    let mut mins = secs / 60;
    let hours = mins / 60;
    secs -= mins * 60;
    mins -= hours * 60;

    (hours, mins as u8, secs as u8)
}

fn format_duration<S>(x: &Duration, s: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    let (hours, mins, secs) = get_hms(x);
    if hours > 0 {
        s.serialize_str(&format!("{}:{:02}:{:02}", hours, mins, secs))
    } else if mins > 0 {
        s.serialize_str(&format!("{}:{:02}", mins, secs))
    } else {
        s.serialize_str(&format!("{}s", secs))
    }
}

#[derive(Serialize)]
struct Output {
    session: SessionStatus,
    #[serde(serialize_with = "format_duration")]
    today_time: Duration,
    #[serde(serialize_with = "format_duration")]
    last_session_time: Duration,
}

struct Args {
    project: String,
}

fn parse_args() -> Result<Args> {
    let mut args = std::env::args();
    args.next().unwrap();
    let project = args.next().ok_or(anyhow!("missing \"project\" argument"))?;
    Ok(Args { project })
}

#[derive(Debug, Clone, Copy, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
enum SessionStatus {
    Finished,
    Started,
}

#[derive(Debug)]
enum WorkingPeriod {
    Today,
    LastSession,
}

async fn subscribe_to_clockin_project(
    project: String,
) -> Result<impl Stream<Item = io::Result<SessionStatus>>> {
    let mut clockin_process = Command::new("clockin")
        .stderr(Stdio::null())
        .stdout(Stdio::piped())
        //.stdin(Stdio::null())
        .env("CLOCKIN_PROJECT", project)
        .arg("subscribe")
        .spawn()?;

    let output = clockin_process.stdout.take().unwrap();
    let output = BufReader::new(output);

    Ok(output.lines().map(|line| {
        line.map(|s| match s.as_str() {
            "finished" => SessionStatus::Finished,
            "started" => SessionStatus::Started,
            line => unreachable!("unexpected clockin output line {line}"),
        })
    }))
}

async fn get_worked_time(project: &str, period: WorkingPeriod) -> Result<Duration> {
    let output = Command::new("clockin")
        .env("CLOCKIN_PROJECT", project)
        .arg("get-worked-time")
        .arg(match period {
            WorkingPeriod::Today => "today",
            WorkingPeriod::LastSession => "last-session",
        })
        .output()
        .await?;
    if !output.status.success() {
        let error_msg = String::from_utf8(output.stdout)?;
        return Err(anyhow!("error while running clockin: {}", error_msg));
    }
    let output = String::from_utf8(output.stdout)?;
    let res = output
        .trim()
        .parse()
        .with_context(|| anyhow!("clockin output: {}", output))?;

    Ok(Duration::from_secs_f64(res))
}

fn print_status(status: Output) {
    println!("{}", serde_json::to_string(&status).unwrap());
}

struct Times {
    today: Duration,
    last_session: Duration,
}

async fn print_until_stopped(
    times: Times,
    last_session_start: Instant,
    rx: &mut (impl Stream<Item = io::Result<SessionStatus>> + Unpin),
) -> SessionStatus {
    loop {
        print_status(Output {
            session: SessionStatus::Started,
            today_time: times.today + last_session_start.elapsed(),
            last_session_time: times.last_session + last_session_start.elapsed(),
        });

        let recv = io::timeout(
            Duration::from_secs(1),
            rx.next().map(|v| v.expect("stream should not end")),
        )
        .await;

        match recv {
            Ok(status) => {
                return status;
            }
            Err(err) if err.kind() == io::ErrorKind::TimedOut => {}
            Err(err) => {
                eprintln!("io error: {err}")
            }
        }
    }
}

async fn get_times(project: &str) -> Result<Times> {
    let today = get_worked_time(&project, WorkingPeriod::Today).await?;
    let last_session = get_worked_time(&project, WorkingPeriod::LastSession).await?;

    Ok(Times {
        today,
        last_session,
    })
}

async fn printer(project: String, mut rx: impl Stream<Item = io::Result<SessionStatus>> + Unpin) {
    let mut state = SessionStatus::Finished;
    loop {
        let times = get_times(&project).await.unwrap();
        print_status(Output {
            session: SessionStatus::Finished,
            today_time: times.today,
            last_session_time: times.last_session,
        });
        while state != SessionStatus::Started {
            state = rx.next().await.expect("stream should not end").unwrap();
        }
        let times = get_times(&project).await.unwrap();
        if state == SessionStatus::Started {
            state = print_until_stopped(times, Instant::now(), &mut rx).await;
        }
    }
}

#[async_std::main]
async fn main() {
    let args = parse_args().expect("invalid cli arguments");

    let subscription = subscribe_to_clockin_project(args.project.clone())
        .await
        .unwrap();

    let printer = printer(args.project, subscription);

    printer.await;
}
