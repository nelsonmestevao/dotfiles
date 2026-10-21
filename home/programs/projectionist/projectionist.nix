{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    (callPackage ./package.nix { })
  ];

  # ── Shell Integration (zsh) ──────────────────────────────────────────
  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    alias pj=projectionist;
  '';
}
