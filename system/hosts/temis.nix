{
  pkgs,
  ...
}:
{
  # ── System ───────────────────────────────────────────────────────────
  dotfiles.modules.boot.enable = true;
  dotfiles.modules.locale.enable = true;

  # ── Boot ─────────────────────────────────────────────────────────────
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.configurationLimit = 10;

  # ── Keyboard ─────────────────────────────────────────────────────────
  services.xserver.xkb.layout = "us";
  console.keyMap = "us";

  # ── Networking ───────────────────────────────────────────────────────
  dotfiles.modules.networking.enable = true;
  dotfiles.modules.tailscale.enable = true;
  services.openssh.enable = true;

  networking.firewall.enable = false;

  # ── Packages & Virtualisation ────────────────────────────────────────
  dotfiles.modules.docker.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  # `system.stateVersion` comes from this host's entry in config/hosts.nix.
}
