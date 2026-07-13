{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    neovim
    # Elixir language server (used by nvim LSP as `expert`). Installed via nix
    # rather than mason because mason ships burrito-packed binaries that don't
    # run on NixOS.
    beamPackages.expert
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
  };

  xdg.configFile."nvim/init.lua" = mkSymlink "init.lua";
}
