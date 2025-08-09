{
  pkgs,
  lib,
  username,
  ...
}:
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
        User = username;
      };
    };

    environment.systemPackages = with pkgs; [
      (pkgs.writeShellScriptBin "${name}" ''
        systemctl start ${name}.service
      '')

      (pkgs.writeShellScriptBin "${name}-logs" ''
        journalctl -eu ${name}.service
      '')
    ];
  };
in
lib.mkMerge [
  (mkSystemTimer "backup-books" "Mon..Fri 17:00" ''
    set -eu
    mkdir -p ~/.logs/rclone
    ${pkgs.rclone}/bin/rclone sync ~/Books gdrive:Backups/Calibre -v \
      --log-file=$HOME/.logs/rclone/backup-books.log
  '')

  # check logs with journalctl -fu backup-system.service
  (mkSystemTimer "backup-system" "Fri 18:00" ''
    ${pkgs.restic}/bin/restic -r rclone:mega:Backups/restic/framework.repo backup \
      --compression max --password-file ~/.config/restic/restic.pw --exclude-file ~/.dotfiles/restic/exclude.txt -v \
      ~/Archive ~/Books ~/Code ~/Documents ~/Downloads ~/Pictures ~/Videos

    ${pkgs.restic}/bin/restic -r rclone:dropbox:Backups/restic/framework.repo backup \
      --compression max --password-file ~/.config/restic/restic.pw --exclude-file ~/.dotfiles/restic/exclude.txt -v \
      ~/Archive ~/Books ~/Code ~/Documents ~/Downloads ~/Pictures ~/Videos

    ${pkgs.restic}/bin/restic -r rclone:mdrive:Backups/restic/framework.repo backup \
      --compression max --password-file ~/.config/restic/restic.pw --exclude-file ~/.dotfiles/restic/exclude.txt -v \
      ~/Archive ~/Books ~/Code ~/Documents ~/Downloads ~/Pictures ~/Videos

    ${pkgs.restic}/bin/restic -r rclone:tpshare:G/backups/framework.repo backup \
      --compression max --password-file ~/.config/restic/restic.pw --exclude-file ~/.dotfiles/restic/exclude.txt -v \
      ~/Archive ~/Books ~/Code ~/Documents ~/Downloads ~/Pictures ~/Videos
  '')
]
