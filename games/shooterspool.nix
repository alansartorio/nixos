{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.games;

  version = "1.10.4";

  gamedir = "drive_c/Program Files (x86)/ShootersPool";

  # Bumped when the layout of the local state below changes, so that a stale
  # writable layer from an older revision of this file gets thrown away rather
  # than shadowing the new prefix.
  generation = "3";

  # The download path carries a per-build token, so bumping the version means
  # grabbing a whole new URL from shooterspool.com, not just editing `version`.
  installer = pkgs.fetchurl {
    name = "ShootersPool-${version}_Setup.exe";
    url = "https://usw-game.shooterspool-cdn.net/${version}/754bv4futcop9yquhc77e2evfb5nbxei/ShootersPool-${version}_Setup.exe";
    hash = "sha256-6xsFW18GH55/t3wRwKp+RLlVPc8Bc/F+upsJRzR+rhA=";
  };

  # A complete wine prefix with the game installed into it, built in the
  # sandbox. Running the real installer rather than unpacking it is what gets
  # Software\ShootersPool\WorkDir written: the game reads that key to find
  # itself and refuses to start without it, along with the protocol handler,
  # the dpi flags and the service registration. It bundles its own
  # redistributables and touches the network for none of this, which is what
  # makes it work under a sandbox with no network at all.
  shooterspool-prefix =
    pkgs.runCommand "shooterspool-prefix-${version}"
      {
        nativeBuildInputs = [
          pkgs.wineWow64Packages.waylandFull
          pkgs.xvfb-run
        ];

        meta = {
          description = "Wine prefix with ShootersPool installed";
          homepage = "https://www.shooterspool.com/";
          license = lib.licenses.unfree;
          platforms = [ "x86_64-linux" ];
        };
      }
      ''
        export HOME=$TMPDIR/home
        mkdir -p "$HOME"

        # Wine builds its font list once, here at prefix creation, from what
        # fontconfig can see. Chromium then walks that list for a last resort
        # fallback font and CHECK-crashes its renderer when it finds none,
        # which shows up as a black webview and a dead "ShootersPool WB.exe".
        # Copying the files into drive_c/windows/Fonts does nothing at all:
        # they have to be visible to fontconfig before the wineboot below.
        export FONTCONFIG_FILE=$TMPDIR/fonts.conf
        printf '%s\n' \
          '<?xml version="1.0"?>' \
          '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' \
          '<fontconfig>' \
          '  <dir>${pkgs.corefonts}/share/fonts</dir>' \
          "  <cachedir>$TMPDIR/fontconfig</cachedir>" \
          '</fontconfig>' > "$FONTCONFIG_FILE"
        # built straight into the output, a 2.8G prefix is not worth copying
        export WINEPREFIX=$out
        export WINEDLLOVERRIDES="mscoree,mshtml="
        export WINEDEBUG=-all
        mkdir -p "$WINEPREFIX"

        xvfb-run -a wineboot --init
        wineserver -w

        # /S is NSIS silent mode, and xvfb is here because the redistributables
        # it chains are GUI installers
        cp ${installer} "$TMPDIR/setup.exe"
        xvfb-run -a wine "$TMPDIR/setup.exe" /S
        wineserver -w

        # start menu bookkeeping, all of it pointing into the build directory
        xvfb-run -a wine reg delete 'HKCU\Software\Wine\MenuFiles' /f || true
        wineserver -w
      '';

  shooterspool = pkgs.writeShellApplication {
    name = "shooterspool";

    runtimeInputs = [
      pkgs.wineWow64Packages.waylandFull
      pkgs.bubblewrap
      pkgs.rsync
      pkgs.util-linux
    ];

    text = ''
      root="''${XDG_DATA_HOME:-$HOME/.local/share}/shooterspool"
      prefix="$root/prefix"

      if [ "$(cat "$root/.generation" 2>/dev/null)" != "${generation}" ]; then
        rm -rf "$root"
      fi
      mkdir -p "$root" "$prefix" "$root/upper" "$root/.work"
      printf %s "${generation}" > "$root/.generation"

      # one namespace per run shares an upper layer with any other, so don't
      exec 9>"$root/.lock"
      flock -n 9 || {
        echo "shooterspool: already running" >&2
        exit 1
      }

      # An overlay can only create entries in a directory that also exists in
      # its writable layer, and every store directory is r-xr-xr-x root, so the
      # directory structure gets mirrored up (dirs only, ~5M). The same pass
      # takes writable copies of the config files, which get rewritten in place
      # and so can't be copied up from a read-only lower file either.
      rsync -a --ignore-existing \
        --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r \
        --include='*/' --include='*.ini' --include='*.json' --exclude='*' \
        ${shooterspool-prefix}/ "$root/upper/"

      exec bwrap \
        --dev-bind / / \
        --overlay-src ${shooterspool-prefix} \
        --overlay "$root/upper" "$root/.work" "$prefix" \
        --setenv WINEPREFIX "$prefix" \
        --setenv WINEARCH win64 \
        --setenv WINEDLLOVERRIDES "mscoree,mshtml=" \
        --chdir "$prefix/${gamedir}/bin" \
        -- wine "ShootersPool Online.exe" "$@"
    '';
  };

  shooterspool-desktop-item = pkgs.makeDesktopItem {
    name = "shooterspool";
    desktopName = "ShootersPool";
    comment = "Billiards simulation";
    exec = "${shooterspool}/bin/shooterspool";
    categories = [
      "Game"
      "Simulation"
    ];
  };
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      shooterspool
      shooterspool-desktop-item
    ];
  };
}
