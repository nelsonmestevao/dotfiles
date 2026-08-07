{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ── System ───────────────────────────────────────────────────────────
  dotfiles.modules.boot.enable = true;
  dotfiles.modules.locale.enable = true;

  # ── Networking ───────────────────────────────────────────────────────
  dotfiles.modules.networking.enable = true;
  services.openssh.enable = true;

  # ── Packages & Virtualisation ────────────────────────────────────────
  dotfiles.modules.docker.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  # `system.stateVersion` is set once for every NixOS host in ../nixos.nix.
}
