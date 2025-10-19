{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.nvim;
in
{
  options.dotfiles.programs.nvim = {
    enable = lib.mkEnableOption "Enable Neovim configuration.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      neovim
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
    };

    xdg.configFile."nvim/init.lua" = config.lib.dotfiles.mkSymlink "nixos/home/programs/nvim/init.lua";
  };
}
