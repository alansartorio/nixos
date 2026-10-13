{
  description = "Alan's NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    clockin.url = "github:alansartorio/clockin";
    clockin.inputs.nixpkgs.follows = "nixpkgs";
    clockin.inputs.flake-utils.follows = "flake-utils";
    rubik.url = "github:alansartorio/rubik";
    rubik.inputs.nixpkgs.follows = "nixpkgs";
    rubik.inputs.flake-utils.follows = "flake-utils";
    croptool.url = "github:alansartorio/croptool";
    croptool.inputs.nixpkgs.follows = "nixpkgs";
    croptool.inputs.flake-utils.follows = "flake-utils";
    pipewire-screenaudio.url = "github:IceDBorn/pipewire-screenaudio";
    #pipewire-screenaudio.url = "path:/home/alan/Documents/PipewireScreenaudio/pipewire-screenaudio";
    pipewire-screenaudio.inputs.nixpkgs.follows = "nixpkgs";
    clipper.url = "github:alansartorio/Clipper/all-merged";
    clipper.inputs.nixpkgs.follows = "nixpkgs";
    clipper.inputs.flake-utils.follows = "flake-utils";
    # Not on any forge: fetched over ssh from the machine that hosts the bare
    # repo, so a `nix flake update` needs that ssh to work.
    #
    # One input where there used to be three. claude-usage, timers and
    # hass-light-eww were a repo each, duplicating their socket framing and
    # their GTK chrome; they now sit in one workspace alongside the kimai
    # integration and the calendar, which is what let them share a holiday
    # calendar, a popup shell and one HTTP client.
    widgets.url = "git+ssh://alan@vibevm/home/alan/git/personal/widgets.git?ref=hass-retry";
    widgets.inputs.nixpkgs.follows = "nixpkgs";
    widgets.inputs.flake-utils.follows = "flake-utils";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      sops-nix,
      ...
    }@inputs:
    let
      # Shared skeleton for every machine. The host directory supplies its
      # hardware, its mounts and its my.* values; everything else is common.
      mkHost =
        name:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./modules/options.nix
            ./modules/identity.nix
            ./modules/nixpkgs.nix
            ./modules/secrets.nix
            sops-nix.nixosModules.sops

            (./hosts + "/${name}")
            ./configuration.nix

            # Make `nix shell nixpkgs#...` resolve to the same nixpkgs the
            # system was built from.
            { nix.registry.nixpkgs.flake = nixpkgs; }

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.alan.imports = [ ./home.nix ];

              # Without this, activation aborts as soon as it finds a file it
              # wants to manage that it did not write -- which on the first
              # switch is every file chezmoi ever applied. Identical files are
              # skipped silently; only genuinely differing ones get moved to
              # <file>.backup.
              home-manager.backupFileExtension = "backup";
            }
          ];
        };
      hosts = {
        desktop = mkHost "desktop";
        laptop = mkHost "laptop";
      };

      # Also expose each host under its own networking.hostName, so a bare
      # `nixos-rebuild switch --flake /path/to/repo` works on the machine
      # itself -- that is how the old flake behaved when it was keyed on
      # system-config.options.hostname. Derived from the config rather than
      # hardcoded, so it cannot drift from hosts/<host>/default.nix.
      byHostname = nixpkgs.lib.mapAttrs' (
        _: host: nixpkgs.lib.nameValuePair host.config.my.hostname host
      ) hosts;
    in
    {
      nixosConfigurations = hosts // byHostname;
    };
}
