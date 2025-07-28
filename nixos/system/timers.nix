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
    ${pkgs.rclone}/bin/rclone sync ~/Books gdrive:Backups/Calibre -v \
      --log-file=~/.logs/rclone/backup-books.log
  '')

  # check logs with journalctl -fu backup-system.service
  (mkSystemTimer "backup-system" "Fri 18:00" ''
    ${pkgs.restic}/bin/restic -r rclone:tpshare:G/backups/framework.repo backup \
      --password-file ~/.config/restic/restic.pw \
      ~/Archive ~/Books ~/Code ~/Documents ~/Downloads ~/Pictures ~/Videos
  '')

]
