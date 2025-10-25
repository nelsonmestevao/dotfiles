# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  lib,
  pkgs,
  hostname,
  username,
  zen-browser,
  ...
}:
{
  imports = [
    ./hosts/framework/hardware.nix
    ./timers.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth.enable = true;

  networking.hostName = hostname;

  networking.extraHosts = ''
    127.0.0.1 livecomp.test
  '';

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Lisbon";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_PT.UTF-8";
    LC_IDENTIFICATION = "pt_PT.UTF-8";
    LC_MEASUREMENT = "pt_PT.UTF-8";
    LC_MONETARY = "pt_PT.UTF-8";
    LC_NAME = "pt_PT.UTF-8";
    LC_NUMERIC = "pt_PT.UTF-8";
    LC_PAPER = "pt_PT.UTF-8";
    LC_TELEPHONE = "pt_PT.UTF-8";
    LC_TIME = "pt_PT.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services = {
    login.enableGnomeKeyring = true;
    gdm.enableGnomeKeyring = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    gedit
    gnome-characters
    gnome-console
    gnome-tour
    yelp
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "pt";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "pt-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = "Nelson Estevão";
    extraGroups = [
      "docker"
      "libvirtd"
      "networkmanager"
      # "vboxusers"
      "wheel"
    ];
    packages = with pkgs; [
      # dev tools
      dconf2nix
      rclone
      # containers
      docker
      docker-compose
      # AppImage
      fuse
      appimage-run
    ];
    shell = pkgs.zsh;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.zsh.enable = true;

  programs.firefox.enable = true;

  services.flatpak.enable = true;

  services.keybase.enable = true;
  services.kbfs.enable = true;
  services.kbfs.mountPoint = "/mnt/kbfs";

  services.tailscale.enable = true;

  programs.nix-ld.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  # virtualisation.virtualbox.host.enable = false;
  # virtualisation.virtualbox.host.enableExtensionPack = false;

  # Fingerprint reader
  services.fprintd.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vagrant
    # virtualbox
    libvirt

    chromedriver
    google-chrome

    brave
    discord
    jetbrains.datagrip
    kdePackages.kdenlive
    obs-cli
    obs-cmd
    obs-studio
    shotcut
    slack
    spotify
    telegram-desktop
    terraform
    vlc
    zen-browser.packages.${pkgs.system}.default

    # security
    fprintd

    # networking
    networkmanager-openconnect
    networkmanager-openvpn
    networkmanager-vpnc
  ];

  environment.variables = {
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05";
}
