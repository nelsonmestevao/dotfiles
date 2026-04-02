{
  config,
  lib,
  pkgs,
  ...
}:

{
  # dotfiles.modules.atd.enable = true;
  # dotfiles.modules.audio.enable = true;
  # dotfiles.modules.boot.enable = true;
  # dotfiles.modules.brave.enable = true;
  # dotfiles.modules.discord.enable = true;
  # dotfiles.modules.fingerprint.enable = true;
  # dotfiles.modules.firefox.enable = true;
  # dotfiles.modules.flatpak.enable = true;
  # dotfiles.modules.gnome.enable = true;
  # dotfiles.modules.kdenlive.enable = true;
  # dotfiles.modules.keybase.enable = true;
  # dotfiles.modules.obs.enable = true;
  # dotfiles.modules.printing.enable = true;
  # dotfiles.modules.shotcut.enable = true;
  # dotfiles.modules.slack.enable = true;
  # dotfiles.modules.spotify.enable = true;
  # dotfiles.modules.tailscale.enable = true;
  # dotfiles.modules.virtualisation.enable = true;
  # dotfiles.modules.vlc.enable = true;

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  dotfiles.modules.networking.enable = true;
  dotfiles.modules.docker.enable = true;
  dotfiles.modules.locale.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
