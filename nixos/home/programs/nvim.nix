{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../lib
  ];

  home.packages = with pkgs; [
    neovim
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  xdg.configFile."nvim/init.lua" = config.lib.dotfiles.mkSymlink "nixos/home/programs/nvim/init.lua";
}
