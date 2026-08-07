//! Move to the next/previous workspace *on a given monitor*, wrapping around
//! within that monitor's slice of the workspace-arranger arrangement.
//!
//! Ported from a rust-script file; the only change is that the unstable
//! `ExitStatus::exit_ok` is replaced with explicit success checks so this
//! builds on stable.

use anyhow::{anyhow, bail, Result};
use serde::{Deserialize, Serialize};
use std::process::Command;

#[derive(Debug, Serialize, Deserialize)]
struct Monitor {
    name: String,
    id: u32,
}

#[derive(Debug, Serialize, Deserialize)]
struct Arrangement {
    monitor: Monitor,
    workspaces: Vec<u32>,
}

fn get_arrangements() -> Result<Vec<Arrangement>> {
    let arrangements_output = Command::new("workspace-arranger").output()?;
    if !arrangements_output.status.success() {
        bail!(
            "workspace-arranger failed with {}",
            arrangements_output.status
        );
    }
    let arrangements_str = String::from_utf8(arrangements_output.stdout)?;
    let arrangements = serde_json::from_str(&arrangements_str)?;
    Ok(arrangements)
}

fn change_to_workspace(target_workspace: u32) -> Result<()> {
    println!("jumping to {target_workspace}");
    let status = Command::new("hyprctl")
        .arg("dispatch")
        .arg("workspace")
        .arg(format!("{target_workspace}"))
        .status()?;
    if !status.success() {
        bail!("hyprctl dispatch workspace failed with {status}");
    }
    Ok(())
}

#[derive(Debug)]
enum Direction {
    Up,
    Down,
}

#[derive(Debug)]
struct Args {
    monitor: u32,
    direction: Direction,
    current: u32,
}

fn parse_args() -> Result<Args> {
    let mut args = std::env::args();
    args.next().unwrap();
    let monitor = args.next().ok_or(anyhow!("missing \"monitor\" argument"))?;
    let direction = args
        .next()
        .ok_or(anyhow!("missing \"direction\" argument"))?;
    let current = args.next().ok_or(anyhow!("missing \"current\" argument"))?;

    let monitor = monitor.parse()?;
    let direction = match direction.as_str() {
        "up" => Direction::Up,
        "down" => Direction::Down,
        _ => Err(anyhow!("invalid direction \"{direction}\""))?,
    };
    let current = current.parse()?;

    Ok(Args {
        monitor,
        direction,
        current,
    })
}

fn main() {
    let arrangements = get_arrangements().unwrap();
    let args = parse_args().unwrap();
    let arrangement = arrangements
        .into_iter()
        .find(|a| a.monitor.id == args.monitor)
        .unwrap();
    let mut index = arrangement
        .workspaces
        .iter()
        .position(|&w| w == args.current)
        .unwrap() as i32;
    match args.direction {
        Direction::Up => index -= 1,
        Direction::Down => index += 1,
    }
    let index = index.rem_euclid(arrangement.workspaces.len() as i32) as usize;
    let target_workspace: u32 = arrangement.workspaces[index];
    change_to_workspace(target_workspace).unwrap();
}
