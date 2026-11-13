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

  # Once a month, delete generations older than 31 days, keeping at least the
  # newest 3 of each profile. nh cleans every profile, the users' home ones
  # too, which nix.gc left alone. bin/autoclean runs the same cleanup by hand
  # (tests/test_autoclean.py keeps the two the same).
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "monthly";
      extraArgs = "--keep-since 31d --keep 3";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ── Users ───────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  # Leave completion setup (compinit) out of /etc/zshrc. oh-my-zsh does it
  # anyway from ~/.zshrc, so a second run would only slow every shell start.
  programs.zsh.enableGlobalCompInit = false;

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
