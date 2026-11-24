{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    (callPackage ./package.nix { dotfilesDirectory = config.dotfiles.directory; })
  ];
}
