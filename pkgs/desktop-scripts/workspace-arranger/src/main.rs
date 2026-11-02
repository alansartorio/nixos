//! Distribute TOTAL_WORKSPACE_AMOUNT workspaces as evenly as possible across
//! the monitors hyprland currently reports, and print the mapping as JSON.
//!
//! Ported from a rust-script file; the only change is that the unstable
//! `ExitStatus::exit_ok` is replaced with an explicit success check so this
//! builds on stable.

use anyhow::{bail, Result};
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

fn get_monitors() -> Result<Vec<Monitor>> {
    let monitors_output = Command::new("hyprctl").arg("monitors").arg("-j").output()?;
    if !monitors_output.status.success() {
        bail!("hyprctl monitors failed with {}", monitors_output.status);
    }
    let monitors_str = String::from_utf8(monitors_output.stdout)?;
    let monitors = serde_json::from_str(&monitors_str)?;
    Ok(monitors)
}

const TOTAL_WORKSPACE_AMOUNT: u32 = 10;

fn main() {
    let mut arrangements: Vec<Arrangement> = vec![];
    let monitors = get_monitors().unwrap();
    let mut monitor_count = monitors.len() as u32;
    let mut workspace_amount: u32 = TOTAL_WORKSPACE_AMOUNT;

    for monitor in monitors {
        let workspaces_in_monitor = workspace_amount / monitor_count;
        arrangements.push(Arrangement {
            monitor,
            workspaces: (0u32..workspaces_in_monitor)
                .map(|n| n + TOTAL_WORKSPACE_AMOUNT - workspace_amount + 1)
                .collect(),
        });
        workspace_amount -= workspaces_in_monitor;
        monitor_count -= 1;
    }

    let out = serde_json::to_string(&arrangements).unwrap();

    println!("{out}");
}
