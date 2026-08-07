# Application configs that were plain (non-templated) files under chezmoi.
# They are copied verbatim from home/files rather than rewritten as nix
# attribute sets: nothing in them varies per machine, and translating a 20k
# init.lua or an 82k p10k config into nix would add risk for no benefit.
{ ... }:
{
  xdg.configFile = {
    "alacritty/alacritty.toml".source = ./files/alacritty.toml;
    "rofi/config.rasi".source = ./files/rofi.rasi;
    "ideavim/ideavimrc".source = ./files/ideavimrc;
    "mpv/input.conf".source = ./files/mpv-input.conf;

    # Whole directory: init.lua, coc-settings.json, ftplugin/, queries/,
    # ultisnips/, vscode-snippets/.
    "nvim" = {
      source = ./files/nvim;
      recursive = true;
    };
  };

  # Referenced by programs.git.settings.core.excludesFile.
  home.file.".gitignore".source = ./files/gitignore;

  home.file.".local/share/mathstart.py".source = ./files/mathstart.py;
}
