{
  config,
  lib,
  pkgs,
  hostname,
  users,
  ...
}:
{
  imports = [
    ./hosts/${hostname}/hardware.nix
    ./hosts/${hostname}.nix
  ]
  ++ (map (username: ./timers/${username}.nix) (lib.attrNames users));

  # ── Nix ─────────────────────────────────────────────────────────────────
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  # ── Users ───────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  programs.nix-ld.enable = true;

  users.users = lib.mapAttrs (username: userCfg: {
    isNormalUser = true;
    description = userCfg.name;
    extraGroups = userCfg.extraGroups or [ ];
    shell = pkgs.zsh;
  }) users;

  # ── Extra Packages ────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
  ];

  # ──────────────────────────────────────────────────────────────────────
  system.stateVersion = "25.11";
}
