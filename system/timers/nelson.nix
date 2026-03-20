{
  pkgs,
  lib,
  ...
}:
let
  mkSystemTimer = import ../lib/mkSystemTimer.nix {
    inherit pkgs;
    username = "nelson";
  };
in
lib.mkMerge [
  (mkSystemTimer "sync-books" "Mon..Fri 18:00" ''
    ${pkgs.rclone}/bin/rclone sync ~/Books gdrive:Backups/Calibre -v
    # --log-file=$HOME/.logs/rclone/backup-books.log
  '')

  (mkSystemTimer "backup-system" "Mon..Fri 17:00" ''
    ${pkgs.restic}/bin/restic -r rclone:mega:Backups/restic/framework.repo backup \
      --compression max --password-file ~/.config/restic/restic.pw --exclude-file ~/.dotfiles/home/programs/restic/exclude.txt -v \
      ~/Archive ~/Books ~/Code ~/Documents ~/Downloads ~/Pictures ~/Videos

    ${pkgs.restic}/bin/restic -r rclone:mdrive:Backups/restic/framework.repo backup \
      --compression max --password-file ~/.config/restic/restic.pw --exclude-file ~/.dotfiles/home/programs/restic/exclude.txt -v \
      ~/Archive ~/Books ~/Code ~/Documents ~/Downloads ~/Pictures ~/Videos

    ${pkgs.restic}/bin/restic -r rclone:tpshare:G/backups/framework.repo backup \
      --compression max --password-file ~/.config/restic/restic.pw --exclude-file ~/.dotfiles/home/programs/restic/exclude.txt -v \
      ~/Archive ~/Books ~/Code ~/Documents ~/Downloads ~/Pictures ~/Videos
  '')

  (mkSystemTimer "backup-dbclient" "hourly" ''
    cd $HOME/.dbclient/query || exit 1
    ${pkgs.git}/bin/git diff --quiet && exit 0
    ${pkgs.git}/bin/git add --all
    ${pkgs.git}/bin/git commit --no-verify --no-gpg-sign --message "$(${pkgs.curl}/bin/curl -s https://whatthecommit.com/index.txt)"
    GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i $HOME/.ssh/id_ed25519" ${pkgs.git}/bin/git push
  '')
]
