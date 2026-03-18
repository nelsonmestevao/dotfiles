{ pkgs, username }:
name: onCalendar: scriptCmd: {
  systemd.timers."${name}" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "${name}.service";
      OnCalendar = onCalendar;
      Persistent = true;
    };
  };

  systemd.services."${name}" = {
    script = scriptCmd;
    serviceConfig = {
      Type = "oneshot";
      User = username;
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "${name}" ''
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
    '')
  ];
}
