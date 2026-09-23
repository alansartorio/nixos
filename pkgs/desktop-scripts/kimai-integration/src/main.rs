//! Feeds the bar's kimai widget: a JSON line on stdout whenever the reading
//! changes, forever.
//!
//!     kimai-integration https://kimai.intra.chyps.com.ar
//!
//! The API token is read from $KIMAI_TOKEN_FILE (default ~/.config/eww/kimai-token),
//! a Kimai personal API token — profile → API access. Kimai 2.x wants it as
//! `Authorization: Bearer <token>`; the old X-AUTH-USER/X-AUTH-TOKEN pair is gone.
//! The bar sets that variable to the sops secret's path, so the default is only
//! ever the fallback for running this by hand.
//!
//! Two rates, because they answer different questions: the API is asked every
//! POLL_INTERVAL what today looks like, and between those answers the running
//! entry is counted forward locally every TICK_INTERVAL. A clock that only moved
//! on the poll would sit still for a minute at a time, and polling at tick rate
//! would be sixty requests a minute for a number we can add ourselves.
//!
//! A third rate falls out of those two: the rate anything actually changes. With
//! a timer running that is the tick, but idle it is the poll, and with the
//! server away it is never. Emitter drops a reading equal to the one before it,
//! so the bar is only woken when there is something new to show.
//!
//! It never exits: eww's deflisten owns this process for the life of the bar, and
//! an exit would freeze the variable at its last value with nothing to say why. A
//! failed request prints failed=true and the loop carries on, so the widget
//! recovers by itself once the VPN or the server comes back.
//!
//! Ported from a rust-script file: the `#!/usr/bin/env rust-script` line and
//! the embedded ```cargo``` manifest are gone, the dependencies having moved
//! into Cargo.toml. Nothing here links against a library found on the system —
//! ureq brings rustls rather than openssl — which is what a store path moving
//! under a running script used to break.
use anyhow::{Context, Result, anyhow};
use chrono::{DateTime, Duration as ChronoDuration, FixedOffset, Local, TimeZone};
use serde::{Deserialize, Serialize};
use std::io::{self, Write};
use std::path::PathBuf;
use std::thread::sleep;
use std::time::{Duration, Instant};
use ureq::Agent;

const POLL_INTERVAL: Duration = Duration::from_secs(60);
const TICK_INTERVAL: Duration = Duration::from_secs(1);
const REQUEST_TIMEOUT: Duration = Duration::from_secs(15);
/// The ring around the icon fills over a working day.
const DAY_TARGET_SECONDS: i64 = 8 * 3600;

/// What the bar reads. `failed` covers every reason there is no answer — server
/// unreachable, token refused, response unreadable — with the detail in `error`,
/// which the widget shows on hover.
///
/// PartialEq is what lets the emitter drop a reading identical to the last one.
/// Comparing the struct rather than its rendered line means the no-change path
/// never serialises at all, and it compares what the widget actually reads
/// rather than an encoding of it.
#[derive(Serialize, PartialEq)]
struct Output {
    configured: bool,
    ok: bool,
    failed: bool,
    running: bool,
    running_time: String,
    today_time: String,
    day_percent: i64,
    task: String,
    description: String,
    since: String,
    error: String,
}

/// The entries Kimai returns from /timesheets/active, where project and activity
/// come back expanded. Either may be absent depending on how the entry was
/// booked, so the label is built from whichever parts exist.
#[derive(Deserialize)]
struct ActiveEntry {
    begin: String,
    #[serde(default)]
    project: Option<Named>,
    #[serde(default)]
    activity: Option<Named>,
    #[serde(default)]
    description: Option<String>,
}

#[derive(Deserialize)]
struct Named {
    name: String,
}

/// The same records from the collection endpoint, which expands nothing — only
/// whether the entry has finished, and for how long it ran, is needed here.
#[derive(Deserialize)]
struct CollectionEntry {
    #[serde(default)]
    end: Option<String>,
    #[serde(default)]
    duration: Option<i64>,
}

/// Everything the widget cannot invent for itself, refreshed on the slow loop.
struct Snapshot {
    /// Seconds already booked today, running entry excluded — it is counted
    /// forward on every tick instead, so it lands in the total once, live.
    finished_today: i64,
    running: Option<Running>,
}

struct Running {
    /// Clamped to midnight: an entry that began yesterday and is still running
    /// would otherwise pour the whole night into today's total.
    counts_from: DateTime<Local>,
    /// The real start, as the user would read it off a clock.
    since: String,
    task: String,
    description: String,
}

/// clockin's format, kept because the bar reads the same way it used to: the
/// largest unit leads and the smaller ones are padded behind it, so a timer under
/// an hour is not padded out to a leading zero it never needed.
fn format_duration(total: i64) -> String {
    let hours = total / 3600;
    let mins = total % 3600 / 60;
    let secs = total % 60;

    if hours > 0 {
        format!("{}:{:02}:{:02}", hours, mins, secs)
    } else if mins > 0 {
        format!("{}:{:02}", mins, secs)
    } else {
        format!("{}s", secs)
    }
}

/// Kimai returns ISO 8601 with the offset unseparated — `2026-08-07T15:55:38-0300`
/// — which is not RFC 3339, so the strict parser alone would reject every
/// timestamp it sends. Both spellings are accepted rather than betting on one.
fn parse_timestamp(raw: &str) -> Result<DateTime<Local>> {
    let parsed = DateTime::parse_from_rfc3339(raw)
        .or_else(|_| DateTime::<FixedOffset>::parse_from_str(raw, "%Y-%m-%dT%H:%M:%S%z"))
        .with_context(|| format!("unreadable timestamp {raw:?}"))?;
    Ok(parsed.with_timezone(&Local))
}

fn midnight() -> DateTime<Local> {
    let today = Local::now().date_naive();
    Local
        .from_local_datetime(&today.and_hms_opt(0, 0, 0).expect("midnight always exists"))
        .earliest()
        // A DST jump that skips midnight leaves no local 00:00 to name; the
        // first instant of the day that does exist is the honest floor.
        .unwrap_or_else(Local::now)
}

fn token_path() -> PathBuf {
    match std::env::var("KIMAI_TOKEN_FILE") {
        Ok(path) => PathBuf::from(path),
        Err(_) => PathBuf::from(std::env::var("HOME").expect("HOME is not set"))
            .join(".config/eww/kimai-token"),
    }
}

/// Owns stdout and the last reading written to it.
///
/// The tick rate and the rate at which anything changes are two different
/// things: a running entry really does read differently every second, but an
/// idle one only moves when the poll lands a minute later, and a failure repeats
/// its one error string for as long as the server stays away. Sending those
/// unchanged is a variable update and a widget re-render sixty times a minute
/// for nothing.
///
/// Suppressing them is safe because eww's deflisten keeps the last value it was
/// given — there is no keepalive to maintain, and nothing to re-send after a
/// quiet stretch.
struct Emitter {
    last: Option<Output>,
}

impl Emitter {
    fn new() -> Self {
        Self { last: None }
    }

    fn send(&mut self, output: Output) {
        if self.last.as_ref() == Some(&output) {
            return;
        }

        let line = serde_json::to_string(&output).expect("output is always serialisable");

        // Rust's stdout is line buffered, so each line reaches the listening bar
        // as it is written rather than waiting for a full buffer.
        //
        // The bar closing the pipe — a reload, an eww restart — is this
        // process's job ending, not a crash to report. println! would panic and
        // leave a backtrace in eww's log for something entirely expected.
        if writeln!(io::stdout(), "{line}").is_err() {
            std::process::exit(0);
        }

        self.last = Some(output);
    }

    fn failure(&mut self, error: &str) {
        self.send(Output {
            configured: true,
            ok: false,
            failed: true,
            running: false,
            running_time: format_duration(0),
            today_time: format_duration(0),
            day_percent: 0,
            task: String::new(),
            description: String::new(),
            since: String::new(),
            error: error.to_string(),
        });
    }

    fn snapshot(&mut self, snapshot: &Snapshot) {
        let (running_secs, task, description, since) = match &snapshot.running {
            Some(running) => (
                (Local::now() - running.counts_from)
                    .num_seconds()
                    .max(0),
                running.task.clone(),
                running.description.clone(),
                running.since.clone(),
            ),
            None => (0, String::new(), String::new(), String::new()),
        };

        let today_secs = snapshot.finished_today + running_secs;

        self.send(Output {
            configured: true,
            ok: true,
            failed: false,
            running: snapshot.running.is_some(),
            running_time: format_duration(running_secs),
            today_time: format_duration(today_secs),
            day_percent: (today_secs * 100 / DAY_TARGET_SECONDS).min(100),
            task,
            description,
            since,
            error: String::new(),
        });
    }
}

fn api_get(agent: &Agent, url: &str, token: &str, path: &str) -> Result<String> {
    Ok(agent
        .get(format!("{url}/api/{path}"))
        .header("Authorization", format!("Bearer {token}"))
        .header("Accept", "application/json")
        .call()?
        .body_mut()
        .read_to_string()?)
}

fn poll(agent: &Agent, url: &str, token: &str) -> Result<Snapshot> {
    let floor = midnight();
    let day_end = floor + ChronoDuration::days(1) - ChronoDuration::seconds(1);
    let stamp = |at: DateTime<Local>| at.format("%Y-%m-%dT%H:%M:%S").to_string();

    // A record still running has end=null, which the `end` filter drops — hence
    // two requests. It also keeps the sum honest: /active is counted forward
    // from its begin, the rest are taken at their stored duration.
    let active: Vec<ActiveEntry> =
        serde_json::from_str(&api_get(agent, url, token, "timesheets/active")?)
            .context("cannot read the active timesheet")?;

    // size=200: a day's entries, with room to spare. The API defaults to 50.
    let finished: Vec<CollectionEntry> = serde_json::from_str(&api_get(
        agent,
        url,
        token,
        &format!(
            "timesheets?begin={}&end={}&size=200",
            stamp(floor),
            stamp(day_end)
        ),
    )?)
    .context("cannot read the timesheet list")?;

    // end.is_some() drops the running record, which this endpoint returns too
    // (at duration 0) despite the `end` filter.
    let finished_today = finished
        .iter()
        .filter(|entry| entry.end.is_some())
        .map(|entry| entry.duration.unwrap_or(0))
        .sum();

    // Kimai returns the newest first; with several clocks running at once the
    // bar can only show one, and the one just started is the one being watched.
    let running = match active.first() {
        None => None,
        Some(entry) => {
            let begin = parse_timestamp(&entry.begin)?;
            let task = [&entry.project, &entry.activity]
                .iter()
                .filter_map(|part| part.as_ref().map(|named| named.name.as_str()))
                .collect::<Vec<_>>()
                .join(" / ");

            Some(Running {
                counts_from: begin.max(floor),
                since: begin.format("%H:%M").to_string(),
                task,
                description: entry.description.clone().unwrap_or_default(),
            })
        }
    };

    Ok(Snapshot {
        finished_today,
        running,
    })
}

/// Errors arrive as a chain — "cannot read the timesheet list: expected value at
/// line 1" says more than either half alone, and the widget has one line to say
/// it in.
fn describe(error: &anyhow::Error) -> String {
    error
        .chain()
        .map(|cause| cause.to_string())
        .collect::<Vec<_>>()
        .join(": ")
}

/// Not fatal, and not a one-shot message either: the file may be about to be
/// written. Say so on the bar, and keep looking.
fn wait_for_token(emitter: &mut Emitter) -> String {
    let path = token_path();
    loop {
        match std::fs::read_to_string(&path) {
            Ok(token) => return token.trim().to_string(),
            Err(_) => {
                // Said once, however long the wait: the message is the same
                // every time round, so the emitter drops the repeats.
                emitter.failure(&format!("no token at {}", path.display()));
                sleep(POLL_INTERVAL);
            }
        }
    }
}

fn parse_args() -> Result<String> {
    let mut args = std::env::args();
    args.next();
    let base_url = args.next().ok_or(anyhow!("missing \"base-url\" argument"))?;
    // Trailing slashes would double up in every request path.
    Ok(base_url.trim_end_matches('/').to_string())
}

fn main() {
    let url = match parse_args() {
        Ok(url) => url,
        Err(error) => {
            eprintln!("usage: kimai-integration <base-url> ({error})");
            std::process::exit(2);
        }
    };

    let mut emitter = Emitter::new();

    let token = wait_for_token(&mut emitter);
    let agent: Agent = Agent::config_builder()
        // Well under POLL_INTERVAL, so a hung request cannot stall the next one.
        .timeout_global(Some(REQUEST_TIMEOUT))
        .build()
        .into();

    let mut state = poll(&agent, &url, &token);
    let mut last_poll = Instant::now();

    loop {
        if last_poll.elapsed() >= POLL_INTERVAL {
            state = poll(&agent, &url, &token);
            last_poll = Instant::now();
        }

        // Still every tick, because a running entry reads differently every
        // tick. The emitter is what keeps an idle one, or a failure, from
        // reaching the bar sixty times a minute unchanged.
        match &state {
            Ok(snapshot) => emitter.snapshot(snapshot),
            Err(error) => emitter.failure(&describe(error)),
        }

        sleep(TICK_INTERVAL);
    }
}
