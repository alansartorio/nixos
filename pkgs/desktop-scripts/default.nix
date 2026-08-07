{
  lib,
  rustPlatform,
  makeWrapper,
  networkmanager,
  clockin,
  # Only used to put `hyprctl` on the PATH of the hyprland-specific binaries.
  # Left null by default on purpose: pkgs.hyprland currently fails to build
  # (see the "disable hyprland due to build failure" commit), and referencing
  # it unconditionally would drag that failure into every system build. When
  # hyprland works again, pass it in and the wrappers become self-contained.
  hyprland ? null,
}:
rustPlatform.buildRustPackage {
  pname = "desktop-scripts";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./.;
    filter =
      path: type:
      let
        base = baseNameOf path;
      in
      !(type == "directory" && (base == "target" || base == "result"));
  };

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ makeWrapper ];

  postInstall =
    let
      hyprPath = lib.optionalString (hyprland != null) "${lib.makeBinPath [ hyprland ]}:";
    in
    ''
      # workspace-arranger and change-active-workspace drive hyprctl;
      # change-active-workspace also shells out to workspace-arranger.
      wrapProgram $out/bin/workspace-arranger \
        --prefix PATH : "${hyprPath}$out/bin"
      wrapProgram $out/bin/change-active-workspace \
        --prefix PATH : "${hyprPath}$out/bin"

      wrapProgram $out/bin/poll-vpn-status \
        --prefix PATH : ${lib.makeBinPath [ networkmanager ]}

      wrapProgram $out/bin/clockin-integration \
        --prefix PATH : ${lib.makeBinPath [ clockin ]}
    '';

  meta = {
    description = "Small helpers driving the eww bar and hyprland workspaces";
    platforms = lib.platforms.linux;
  };
}
