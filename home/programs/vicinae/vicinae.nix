{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The settings from this repo. vicinae reads them on top of its own
  # settings.json, which the app still writes to.
  settings = (pkgs.formats.json { }).generate "vicinae-settings.json" {
    theme = {
      light = {
        name = "vicinae-light";
        icon_theme = "default";
      };
      dark = {
        name = "vicinae-dark";
        icon_theme = "default";
      };
    };
    keybinding = "emacs";
    keybinds.toggle-action-panel = "control+L";
    launcher_window.opacity = 0.98;
    favorites = [
      "applications:slack"
      "applications:spotify"
      "applications:zen"
      "clipboard:history"
    ];
    providers.calculator.preferences.backend = "numen";
  };

  # vicinae with three settings that its own flake used to add. They go on the
  # command, not the service, so a `vicinae server` started by hand gets them
  # too. Remove a line once nixpkgs adds it; with none left, use
  # `pkgs.vicinae` as it is.
  wrapperArgs = [
    # The settings above.
    "--set VICINAE_OVERRIDES ${settings}"
    # The paste helper with the rights it needs (see
    # system/modules/nixos/vicinae). A host without it keeps vicinae's own copy.
    "--run ${lib.escapeShellArg "if [ -x ${inputServer} ]; then export VICINAE_INPUT_SERVER_BIN=${inputServer}; fi"}"
    # vicinae calls `pactl`.
    "--prefix PATH : ${lib.getBin pkgs.pulseaudio}/bin"
  ];
  inputServer = "/run/wrappers/bin/vicinae-input-server";

  package = pkgs.symlinkJoin {
    name = "${pkgs.vicinae.name}-configured";
    paths = [ pkgs.vicinae ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/vicinae ${lib.concatStringsSep " " wrapperArgs}";
    meta.mainProgram = "vicinae";
  };

  # vicinae was 0.30.0 before this change, so the warning below says to back up
  # first. Once nixpkgs has that version, it stops, and pkgs.expiry says to
  # delete it.
  previousVersion =
    pkgs.expiry.expiresWhen (lib.versionAtLeast pkgs.vicinae.version "0.30.0")
      "nixpkgs has vicinae 0.30.0 now. Delete the downgrade warning in home/programs/vicinae/vicinae.nix."
      "0.30.0";
in
{
  # Runs as a systemd user service under Wayland.
  platforms = [ "linux" ];

  # For vicinae's media and volume commands, and for you in a terminal.
  home.packages = with pkgs; [
    playerctl
    pulseaudio
  ];

  programs.vicinae = {
    enable = true;
    inherit package;
    systemd.enable = true;
  };

  warnings = lib.optional (lib.versionOlder pkgs.vicinae.version previousVersion) ''
    vicinae ${pkgs.vicinae.version} is older than the ${previousVersion} this host ran.
    Back up ~/.config/vicinae and ~/.local/share/vicinae before you switch.
  '';

  # ── GNOME ─────────────────────────────────────────────────────────────
  dotfiles.programs.gnome.extensions.vicinae.enable = config.dotfiles.programs.gnome.enable;

  dconf.settings = lib.mkIf config.dotfiles.programs.gnome.enable {
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Vicinae";
      command = "vicinae toggle";
      binding = "<Alt>Space";
    };
  };
}
