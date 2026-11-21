# A timer that runs a script as `username`:
#
#   mkSystemTimer "name" "when" tools ''script''
#
# `tools` are the packages the script's commands come from, so the script
# says `git`, not the path of git in the store. The timer also gets a command
# of its own name, to start it by hand, see its status or read its logs.
{ pkgs, username }:
name: onCalendar: tools: scriptCmd: {
  systemd.timers.${name} = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "${name}.service";
      OnCalendar = onCalendar;
      Persistent = true;
    };
  };

  systemd.services.${name} = {
    path = tools;
    script = scriptCmd;
    # Tell the user on the desktop when it fails (see ../timers/default.nix).
    unitConfig.OnFailure = "notify-failure@%N.service";
    serviceConfig = {
      Type = "oneshot";
      User = username;
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin name ''
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
