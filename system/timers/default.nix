# Per-user timers (backups, syncs). Each user's timers live in ./<username>.nix.
# A host turns them on and picks which of its users get them:
#
#   dotfiles.modules.timers.enable = true;
#   dotfiles.modules.timers.users = [ "nelson" ];
#
# Every user file is imported on every NixOS host, so the set of modules never
# depends on config; each file only takes effect for the users picked here.
{
  config,
  lib,
  pkgs,
  users,
  ...
}:
let
  cfg = config.dotfiles.modules.timers;

  # This host's users that have a timers file. A user without one gets none.
  usersWithTimers = lib.filter (username: builtins.pathExists ./${username}.nix) (
    lib.attrNames users
  );

  # The user's file as a module that only applies when the host picks the user.
  # It takes the same arguments as the file, because the module system only
  # passes the arguments a module names.
  timersFor =
    username:
    let
      timers = import ./${username}.nix username;
    in
    lib.mirrorFunctionArgs timers (args: {
      _file = ./${username}.nix;
      config = lib.mkIf (cfg.enable && lib.elem username cfg.users) (timers args);
    });
in
{
  imports = map timersFor usersWithTimers;

  options.dotfiles.modules.timers = {
    enable = lib.mkEnableOption "the timers of the users picked in `users`";
    users = lib.mkOption {
      type = lib.types.listOf (lib.types.enum usersWithTimers);
      default = [ ];
      example = [ "nelson" ];
      description = "This host's users whose timers (./<username>.nix) run here.";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.enable -> cfg.users != [ ];
        message = "dotfiles.modules.timers is enabled, but dotfiles.modules.timers.users is empty. Pick the users whose timers should run.";
      }
    ];

    # A timer that fails shows a notice on its user's desktop. Without it, the
    # only sign is in the journal, where nobody looks. The helpers in ../lib
    # point every unit they make here, with `OnFailure`.
    systemd.services."notify-failure@" = lib.mkIf cfg.enable {
      description = "Tell its user that %i failed";
      path = with pkgs; [
        libnotify
        util-linux
      ];
      serviceConfig.Type = "oneshot";
      scriptArgs = "%i";
      # This runs as root, so it can ask systemd which user the failed unit
      # runs as, and speak on that user's own session bus, where the desktop
      # listens. With nobody logged in there is no bus, and the notice fails
      # without a sound: there is nobody to tell.
      script = ''
        user=$(systemctl show --property=User --value "$1.service")
        [ -n "$user" ] || exit 0
        runuser -u "$user" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$user")/bus" \
          notify-send --urgency=critical --icon=dialog-error "$1 failed" "To see why: journalctl -eu $1"
      '';
    };
  };
}
