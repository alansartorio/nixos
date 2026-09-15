# zsh, bash and the shell environment, migrated off chezmoi.
#
# oh-my-zsh and powerlevel10k used to be fetched as tarballs by
# .chezmoiexternal.toml (a github master branch and a pinned p10k tag); both now
# come from nixpkgs, so they are pinned by flake.lock like everything else.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;

    # Pinned explicitly: home-manager is going to move this default to
    # $XDG_CONFIG_HOME/zsh once stateVersion reaches 26.05, and the dotfiles
    # being migrated here all assume ~/.zshrc.
    dotDir = config.home.homeDirectory;

    oh-my-zsh = {
      enable = true;
      # powerlevel10k is not one of oh-my-zsh's bundled themes; it is loaded as
      # a plugin below, so leave oh-my-zsh's own theme unset.
      theme = "";
      plugins = [
        "git"
        "fastfile"
      ];
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initContent = lib.mkMerge [
      # Must run before anything that could prompt, and before oh-my-zsh
      # (which injects at order 800).
      (lib.mkOrder 500 ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # Read by the fastfile plugin as it loads, so it has to be set first.
      (lib.mkOrder 550 ''
        fastfile_var_prefix='@'
      '')

      (lib.mkAfter ''
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      '')

      (lib.mkAfter ''
        rrsync() {
          if [ $# -lt 2 ]; then
            printf 'rrsync: needs src and dest\n' >&2
            return 2
          fi
          local opts=()
          while [ $# -gt 2 ]; do
            opts+=("$1")
            shift
          done
          command rsync "''${opts[@]}" "$2" "$1"
        }
      '')
    ];
  };

  home.file.".p10k.zsh".source = ./files/p10k.zsh;

  programs.bash = {
    enable = true;
    # The old .bashrc was the Arch skeleton with everything commented out; the
    # interactive guard is all that was left of it.
    initExtra = "";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    PROJECTS = "${config.home.homeDirectory}/Documents/Code";

    CHROME_EXECUTABLE = "chromium";
    NEOVIDE_MULTIGRID = "1";

    # Java/AWT fixes for tiling wayland compositors.
    _JAVA_AWT_WM_NONREPARENTING = "1";
    _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd";

    # Keep tool state out of $HOME.
    ANDROID_HOME = "${config.xdg.dataHome}/android";
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    WINEPREFIX = "${config.xdg.dataHome}/wine";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    PLATFORMIO_CORE_DIR = "${config.xdg.dataHome}/platformio";
    npm_config_prefix = "${config.home.homeDirectory}/.local";
    R_LIBS_USER = "${config.home.homeDirectory}/R/lib";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.local/share/JetBrains/Toolbox/scripts"
  ];

  xdg.enable = true;
}
