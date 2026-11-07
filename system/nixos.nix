{
  lib,
  pkgs,
  hostname,
  users,
  host,
  ...
}:
{
  imports = [
    ./hosts/${hostname}/hardware.nix
    ./hosts/${hostname}.nix
    # Off unless the host turns it on for some of its users.
    ./timers
  ];

  # ── Nix ─────────────────────────────────────────────────────────────────
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.auto-optimise-store = true;

  boot.tmp.cleanOnBoot = true;

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 31d";
  };

  nixpkgs.config.allowUnfree = true;

  # ── Users ───────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  programs.nix-ld.enable = true;

  users.users = lib.mapAttrs (_username: userCfg: {
    isNormalUser = true;
    description = userCfg.name;
    extraGroups = userCfg.extraGroups or [ ];
    shell = pkgs.zsh;
  }) users;

  # ── Extra Packages ────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
  ];

  # ──────────────────────────────────────────────────────────────────────
  # The release this host was first installed with; see config/hosts.nix.
  system.stateVersion = host.stateVersion;
}
