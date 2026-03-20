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
  users.users = lib.mapAttrs (username: userCfg: {
    isNormalUser = true;
    description = userCfg.name;
    extraGroups = [
      "docker"
      "libvirtd"
      "lpadmin"
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      dconf2nix
      fuse
      appimage-run
    ];
    shell = pkgs.zsh;
  }) users;

  # ── Programs & Services ────────────────────────────────────────────────
  programs.zsh.enable = true;
  programs.firefox.enable = true;
  programs.nix-ld.enable = true;

  services.atd.enable = true;

  environment.systemPackages = with pkgs; [
    brave
    discord
    kdePackages.kdenlive
    shotcut
    slack
    spotify
    vlc
  ];

  # ──────────────────────────────────────────────────────────────────────
  system.stateVersion = "25.11";
}
