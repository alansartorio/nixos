{ pkgs, system-config, ... }:
let
  lib = pkgs.lib;
  docker = with pkgs; [
    dive
    #podman-tui
    docker-compose
    #podman-compose
  ];
  gui = with pkgs; [
    vscode.fhs
  ];
in
{
  environment.systemPackages =
    (with pkgs; [
      # editors
      (pkgs.symlinkJoin {
        name = "neovim-custom";
        paths = [ neovim-unwrapped ];

        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/nvim \
            --prefix PATH : ${lib.makeBinPath [tree-sitter]}
        '';
      })

      # sdks/interpreters/compilers
      (dotnetCorePackages.combinePackages [
        dotnetCorePackages.dotnet_8.sdk
        dotnetCorePackages.dotnet_8.aspnetcore
        dotnetCorePackages.dotnet_9.sdk
      ])
      python3
      gnuplot
      gnumake
      gcc
      rustup # install rustanalyzer after
      cmake
      nodejs_latest
      go
      love
      luajit
      jq
      terraform
      biome

      # tools
      sqlite
      csharprepl
      gopls
      pyright
      basedpyright
      luarocks
      rust-script

      # LSPs/formatters
      nixfmt
      prettier
      ruff
      lua-language-server
      jdt-language-server
      roslyn-ls
      typescript-language-server
      nixd
      terraform-ls
      bash-language-server
      clang-tools
      clang-manpages
      man-pages-posix

      pkg-config
      gitflow
      git-filter-repo
    ])
    ++ docker
    ++ gui;
}
