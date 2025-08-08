# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  lib,
  pkgs,
  hostname,
  zen-browser,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hosts/framework/hardware.nix
    ./timers.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  programs.zsh.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nelson = {
    isNormalUser = true;
    description = "Nelson Estevão";
    extraGroups = [
      "docker"
      "libvirtd"
      "networkmanager"
      "vboxusers"
      "wheel"
    ];
    packages = with pkgs; [
      # dev tools
      dconf2nix
      rclone
      restic
      xonsh
      # docker
      docker
      docker-compose
      # AppImage
      fuse
      appimage-run
    ];
    shell = pkgs.zsh;
  };

  # Install firefox.
  programs.firefox.enable = true;

  services.flatpak.enable = true;

  services.keybase.enable = true;
  services.kbfs.enable = true;

  services.tailscale.enable = true;

  programs.nix-ld.enable = true;

  # Fingerprint reader
  services.fprintd.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    hyprcursor
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    pyprland
    waybar

    vagrant
    virtualbox
    libvirt

    chromedriver
    google-chrome

    brave
    discord
    ghostty
    jetbrains.datagrip
    kdePackages.kdenlive
    nerd-fonts.jetbrains-mono
    obs-cli
    obs-cmd
    obs-studio
    shotcut
    slack
    spotify
    telegram-desktop
    terraform
    vlc
    vscode
    wezterm
    zed-editor
    zen-browser.packages.${pkgs.system}.default
    # security
    fprintd
    # file system
    ntfs3g
    # networking
    networkmanager-openconnect
    networkmanager-openvpn
    networkmanager-vpnc
  ];

  environment.variables = { };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
