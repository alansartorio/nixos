//! Poll a NetworkManager connection's up/down state once a second and print it
//! whenever it changes. Consumed by the eww bar's VPN toggle.
//!
//! Ported verbatim from a rust-script file, minus the unstable
//! `#![feature(exit_status_error)]` attribute, which was declared but unused.

use anyhow::{anyhow, Result};
use std::process::Command;
use std::thread::sleep;
use std::time::Duration;

struct Args {
    connection: String,
}

fn parse_args() -> Result<Args> {
    let mut args = std::env::args();
    args.next().unwrap();
    let connection = args
        .next()
        .ok_or(anyhow!("missing \"connection\" argument"))?;
    Ok(Args { connection })
}

fn get_connection_state(connection: &str) -> Result<bool> {
    let res = Command::new("nmcli")
        .args(["-f", "GENERAL.STATE", "dev", "show", connection])
        .output()?;

    Ok(res.status.success())
}

fn main() {
    let args = parse_args().expect("invalid cli arguments");

    let mut prev_state = None;
    loop {
        if let Ok(state) = get_connection_state(&args.connection) {
            if !prev_state.is_some_and(|prev_state| prev_state == state) {
                println!("{state}");
            }
            prev_state.replace(state);
        }
        sleep(Duration::from_secs(1));
    }
}
