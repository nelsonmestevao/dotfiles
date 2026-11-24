{
  pkgs,
  ...
}:
{
  # ── System ───────────────────────────────────────────────────────────
  services.atd.enable = true;
  services.fwupd.enable = true;
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
  boot.plymouth.enable = true;

  # ── Keyboard ─────────────────────────────────────────────────────────
  services.xserver.xkb.layout = "pt";
  console.keyMap = "pt-latin1";

  # Lets the logged-in user set the keyboard light (`mode -k` in ~/.spells).
  # The Laptop 16 input modules are QMK devices, and their hidraw nodes are
  # root-only by default. The product IDs are the ANSI keyboard, RGB macropad,
  # numpad, ISO keyboard and JIS keyboard.
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0012|0013|0014|0018|0019", TAG+="uaccess"
  '';

  # ── Networking ───────────────────────────────────────────────────────
  dotfiles.modules.networking.enable = true;
  services.tailscale.enable = true;

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
  programs.firefox.enable = true;

  # ── Communication ────────────────────────────────────────────────────
  dotfiles.modules.keybase.enable = true;

  # ── Packages & Virtualisation ────────────────────────────────────────
  dotfiles.modules.docker.enable = true;
  services.flatpak.enable = true;
  dotfiles.modules.virtualisation.enable = true;
}
