# The shell scripts that drive the eww bar and the compositor session.
#
# Under chezmoi these lived in ~/.config/eww/bar/scripts and ~/.local/bin and
# found their dependencies by luck of $PATH. Each one is a wrapped derivation
# now, so jq/socat/eww/etc are in its closure.
#
# Dropped on the way over: `getram` (nothing referenced it -- the bar reads
# EWW_RAM.used_mem_perc directly) and `kb_layouts` (referenced only from the
# commented-out keyboard widget, and the script never existed in the repo).
#
# And later `popup_calendar`, which opened and closed eww's own calendar window
# after pushing today's date into three defvars. The calendar is `calendar-gui`
# now -- a GTK4 layer-shell window that knows the date itself and toggles on
# relaunch -- so the clock spawns it directly and there is nothing left to
# script. `coreutils` went with it: `date` was the only thing that wanted it.
{
  lib,
  symlinkJoin,
  writeShellApplication,
  jq,
  socat,
  eww,
  niri,
  procps,
  findutils,
  pamixer,
  pulseaudio,
  libnotify,
  clockin,
  desktop-scripts,
  # See pkgs/desktop-scripts: pkgs.hyprland is currently disabled over a build
  # failure, so hyprctl is only wired in when a package is passed explicitly.
  hyprland ? null,
}:
let
  hyprPkgs = lib.optional (hyprland != null) hyprland;

  eww-launcher = writeShellApplication {
    name = "eww-launcher";
    runtimeInputs = [
      jq
      socat
      eww
      niri
      procps
    ]
    ++ hyprPkgs;
    text = ''
      # Hyprland assigns monitor_ids consistently, while eww screen ids change
      # over time if monitors are unplugged/plugged; we can use --screen with
      # the monitor model to prevent this.
      get-monitor-model() {
          hyprland_id=$1
          hyprctl monitors -j | jq -r ".[] | select(.id == $hyprland_id) | .model"
      }

      get-monitors() {
          hyprctl monitors -j | jq -r '.[] | .id'
      }

      open-bar() {
          monitor_id=$1
          monitor_model=$(get-monitor-model "$monitor_id")
          if [ "$monitor_id" = 0 ]; then
              bar=main-bar
          else
              bar=secondary-bar
          fi

          eww open --screen "$monitor_model" -c ~/.config/eww/bar --id "$monitor_id" $bar --arg "monitor_id=$monitor_id" --arg "monitor_index=$monitor_id"
      }

      reload-bars() {
          eww close-all -c ~/.config/eww/bar
          get-monitors | while read -r monitor_id; do
              open-bar "$monitor_id"
          done
      }

      handle() {
        case $1 in
          monitoraddedv2*|monitorremovedv2*)
              reload-bars
              ;;
        esac
      }

      get-monitor-model-niri() {
          niri_name=$1
          niri msg -j outputs | jq -r ".[] | select(.name == \"$niri_name\") | .model"
      }

      open-bar-niri() {
          monitor_id=$1
          monitor_model=$(get-monitor-model-niri "$monitor_id")
          if [ "$monitor_id" = "DP-2" ]; then
              bar=main-bar-niri
          else
              bar=secondary-bar-niri
          fi

          eww open --screen "$monitor_model" -c ~/.config/eww/bar --id "$monitor_id" $bar --arg "monitor_id=$monitor_id" --arg "monitor_index=$monitor_id"
      }

      reload-bars-niri() {
        monitors=$1
        echo "closing all"
        eww close-all -c ~/.config/eww/bar
        echo "$monitors" | while read -r output; do
            echo opening "$output"
            open-bar-niri "$output"
        done
      }

      handle-niri() {
        workspaces=$(jq -c '.WorkspacesChanged.workspaces' <<<"$1")
        if ! [ "$workspaces" = "null" ]; then
          active_monitors=$(jq -r '[.[] | .output] | unique | sort_by(.) | .[]' <<<"$workspaces")
          if [ "''${previous_monitors:-}" != "$active_monitors" ]; then
            reload-bars-niri "$active_monitors"
          else
            echo "not reloading, same monitors"
          fi
        fi
        previous_monitors=$active_monitors
      }

      if pidof niri; then
        niri msg -j event-stream | while read -r line; do handle-niri "$line"; done
      elif pidof Hyprland; then
        reload-bars
        socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
      else
        echo "unsupported desktop environment"
      fi
    '';
  };

  hyprland-workspace-binder = writeShellApplication {
    name = "hyprland-workspace-binder";
    runtimeInputs = [
      jq
      socat
      desktop-scripts
    ]
    ++ hyprPkgs;
    text = ''
      rebind-workspaces() {
          arrangement=$(workspace-arranger)
          instructions=$(echo "$arrangement" |
              jq 'map(.monitor as $monitor | .workspaces | map({monitor: $monitor, workspace: .})) | flatten' |
              jq -r 'map("keyword workspace \(.workspace),monitor:\(.monitor.name); dispatch moveworkspacetomonitor \(.workspace) \(.monitor.id)") | join("; ")')

          hyprctl --batch "reload; $instructions"
      }

      handle() {
        case $1 in
          monitoraddedv2*|monitorremovedv2*)
              rebind-workspaces
              ;;
        esac
      }

      rebind-workspaces

      socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
    '';
  };

  get-active-workspace = writeShellApplication {
    name = "get-active-workspace";
    runtimeInputs = [
      jq
      socat
    ]
    ++ hyprPkgs;
    text = ''
      active() {
          hyprctl monitors -j | jq -Mc "map(.activeWorkspace.id)"
      }

      active
      socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r _; do
          active
      done
    '';
  };

  get-workspaces = writeShellApplication {
    name = "get-workspaces";
    runtimeInputs = [
      jq
      socat
      desktop-scripts
    ]
    ++ hyprPkgs;
    text = ''
      spaces() {
          WORKSPACE_WINDOWS=$(hyprctl workspaces -j | jq 'map({key: .id | tostring, value: .windows}) | from_entries')
          workspace-arranger | jq --argjson windows "''${WORKSPACE_WINDOWS}" -Mc 'map(.workspaces | map(tostring) | map({id: ., windows: ($windows[.]//0)}))'
      }

      spaces
      socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r _; do
          spaces
      done
    '';
  };

  getvol = writeShellApplication {
    name = "getvol";
    runtimeInputs = [
      pamixer
      pulseaudio
    ];
    text = ''
      printvol() {
        echo "{\"volume\": $(pamixer --get-volume), \"mute\": $(pamixer --get-mute)}"
      }

      printvol

      pactl subscribe | grep --line-buffered "sink" | while read -r _; do
        printvol
      done
    '';
  };

  sync-clockin = writeShellApplication {
    name = "sync-clockin";
    runtimeInputs = [
      clockin
      libnotify
      findutils
    ];
    text = ''
      eval "$EWW_CMD" update clockin_synching=true

      clockin exec '( git add . && git commit -m "sync" ) || git pull --rebase && git push' |
          xargs -0 notify-send

      eval "$EWW_CMD" update clockin_synching=false
    '';
  };
in
symlinkJoin {
  name = "eww-scripts";
  paths = [
    eww-launcher
    hyprland-workspace-binder
    get-active-workspace
    get-workspaces
    getvol
    sync-clockin
  ];
  meta.description = "Shell helpers for the eww bar and compositor session";
}
