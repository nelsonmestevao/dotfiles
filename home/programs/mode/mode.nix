{
  pkgs,
  ...
}:
{
  # mode, theme, caffeine and notifications. mode edits the VS Code, Zed and
  # Ghostty files in the checkout at $DOTFILES, which the zsh module sets.
  home.packages = with pkgs; [
    (callPackage ./package.nix { })
  ];
}
