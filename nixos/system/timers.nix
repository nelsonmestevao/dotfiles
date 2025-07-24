{ pkgs, lib, ... }:

let
  mkSystemTimer = name: onCalendar: scriptCmd: {
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
        User = "nelson";
      };
    };
  };
in
lib.mkMerge [

  (mkSystemTimer "backup-books" "Mon..Fri 17:00" ''
    set -eu
    mkdir -p ~/.logs/rclone
    ${pkgs.rclone}/bin/rclone sync ~/Books gdrive:Backups/Calibre -v --log-file=~/.logs/rclone/backup-books.log
  '')

  (mkSystemTimer "backup-home-assistant" "Tue,Fri 11:00" ''
    set -eu
    mkdir -p ~/.logs/rclone
    ${pkgs.rclone}/bin/rclone copy ha:/backup gdrive:Backups/home-assistant -v --log-file=~/.logs/rclone/backup-home-assistant.log
  '')

]
