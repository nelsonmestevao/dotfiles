# Timers that run a script as `username`, by name:
#
#   mkSystemTimers {
#     sync-books = {
#       at = "Mon..Fri 18:00";
#       script = "rclone sync ~/Books gdrive:Backups/Calibre";
#     };
#   }
#
# Each one gets a systemd timer and service, and a command of the same name
# that starts it by hand, shows its status or reads its logs.
{
  lib,
  pkgs,
  username,
}:
timers: {
  systemd.timers = lib.mapAttrs (name: timer: {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "${name}.service";
      OnCalendar = timer.at;
      Persistent = true;
    };
  }) timers;

  systemd.services = lib.mapAttrs (_: timer: {
    inherit (timer) script;
    serviceConfig = {
      Type = "oneshot";
      User = username;
    };
  }) timers;

  environment.systemPackages = map (
    name:
    pkgs.writeShellScriptBin name ''
      COMMAND="$1"

      [[ -z "$COMMAND" ]] && COMMAND="start"

      case "$COMMAND" in
        start)
          systemctl start ${name}.service
          ;;
        status)
          systemctl status ${name}.timer
          systemctl status ${name}.service
          ;;
        logs)
          journalctl -eu ${name}.service
          ;;
        *)
          echo "Usage: ${name} (start | status | logs)"
          exit 1
          ;;
      esac
    ''
  ) (lib.attrNames timers);
}
