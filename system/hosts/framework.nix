{
  pkgs,
  ...
}:
{
  # ── System ───────────────────────────────────────────────────────────
  dotfiles.modules.atd.enable = true;
  dotfiles.modules.boot.enable = true;
  dotfiles.modules.fingerprint.enable = true;
  dotfiles.modules.locale.enable = true;
  dotfiles.modules.printing.enable = true;
  dotfiles.modules.swap.enable = true;

  # ── Timers ───────────────────────────────────────────────────────────
  # Runs ../timers/<user>.nix (backups and syncs) for the users picked here.
  dotfiles.modules.timers.enable = true;
  dotfiles.modules.timers.users = [ "nelson" ];

  # ── Boot ─────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Keyboard ─────────────────────────────────────────────────────────
  services.xserver.xkb.layout = "pt";
  console.keyMap = "pt-latin1";

  # ── Networking ───────────────────────────────────────────────────────
  dotfiles.modules.networking.enable = true;
  dotfiles.modules.tailscale.enable = true;

  networking.firewall.enable = true;

  # Allow access to localsend
  networking.firewall.allowedTCPPorts = [
    53317
    53318
  ];
  networking.firewall.allowedUDPPorts = [ 53317 ];

  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
    networkmanager-openvpn
  ];

  # ── Desktop & Audio ──────────────────────────────────────────────────
  dotfiles.modules.audio.enable = true;
  dotfiles.modules.gnome.enable = true;
  dotfiles.modules.vicinae.enable = true;

  # ── Browsers ─────────────────────────────────────────────────────────
  dotfiles.modules.firefox.enable = true;

  # ── Communication ────────────────────────────────────────────────────
  dotfiles.modules.keybase.enable = true;

  # ── Packages & Virtualisation ────────────────────────────────────────
  dotfiles.modules.docker.enable = true;
  dotfiles.modules.flatpak.enable = true;
  dotfiles.modules.virtualisation.enable = true;
}
