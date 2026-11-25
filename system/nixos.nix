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

  # vicinae's own cache. Its flake asks for it in nixConfig, but Nix ignores
  # that for users it doesn't trust, so the system has to add it.
  nix.settings.extra-substituters = [ "https://vicinae.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
  ];

  # vicinae's NixOS module turns its input server on for every host. Here it
  # is off unless the host turns on dotfiles.modules.vicinae.
  programs.vicinae.input-server.enable = lib.mkDefault false;

  boot.tmp.cleanOnBoot = true;

  # Once a month, delete old generations in every profile, the users' homes
  # too, by the rule in config/cleanup.nix. nh itself comes with each home
  # (home/default.nix).
  programs.nh.clean = {
    enable = true;
    dates = "monthly";
    extraArgs = toString (import ../config/cleanup.nix);
  };

  # ── Users ───────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  # Leave completion setup (compinit) out of /etc/zshrc. oh-my-zsh does it
  # anyway from ~/.zshrc, so a second run would only slow every shell start.
  programs.zsh.enableGlobalCompInit = false;

  # Leave the default prompt out of /etc/zshrc too. It loads promptinit and
  # the suse theme on every shell start, and Powerlevel10k replaces it.
  programs.zsh.promptInit = "";

  programs.nix-ld.enable = true;

  users.users = lib.mapAttrs (_username: userCfg: {
    isNormalUser = true;
    description = userCfg.name;
    inherit (userCfg) extraGroups;
    shell = pkgs.zsh;
  }) users;

  # ──────────────────────────────────────────────────────────────────────
  # The release this host was first installed with; see config/hosts.nix.
  system.stateVersion = host.stateVersion;
}
