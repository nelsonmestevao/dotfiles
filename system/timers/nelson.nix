username:
{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:
let
  mkSystemTimer = import ../lib/mkSystemTimer.nix { inherit pkgs username; };
  mkResticBackups = import ../lib/mkResticBackups.nix { inherit lib username; };

  inherit (config.users.users.${username}) home;
in
lib.mkMerge [
  (mkSystemTimer "sync-books" "Mon..Fri 18:00"
    (with pkgs; [
      rclone
    ])
    ''
      rclone sync ~/Books gdrive:Backups/Calibre -v
      # --log-file=$HOME/.logs/rclone/backup-books.log
    ''
  )

  # The same folders go to each repository, one repository per host. Each
  # one has its own hour, so the three don't read the disk at once. The README
  # has the restore drill, which no timer can do for you.
  (mkResticBackups {
    passwordFile = "${home}/.config/restic/restic.pw";
    exclude = ../../home/programs/restic/exclude.txt;
    paths = map (dir: "${home}/${dir}") [
      "Archive"
      "Books"
      "Code"
      "Documents"
      "Downloads"
      "Pictures"
      "Videos"
    ];
    # After each backup, a week of daily snapshots stays, five weekly ones
    # and twelve monthly ones.
    keep = {
      daily = 7;
      weekly = 5;
      monthly = 12;
    };
    repos = {
      mega = {
        repository = "rclone:mega:Backups/restic/${hostname}.repo";
        backupAt = "Mon..Fri 17:00";
      };
      mdrive = {
        repository = "rclone:mdrive:Backups/restic/${hostname}.repo";
        backupAt = "Mon..Fri 18:00";
      };
      tpshare = {
        repository = "rclone:tpshare:G/backups/${hostname}.repo";
        backupAt = "Mon..Fri 19:00";
      };
    };
  })

  (mkSystemTimer "backup-dbclient" "hourly"
    (with pkgs; [
      git
      curl
      openssh
    ])
    ''
      cd $HOME/.dbclient/query || exit 1
      git diff --quiet && exit 0
      git add --all
      git commit --no-verify --no-gpg-sign --message "$(curl -s https://whatthecommit.com/index.txt)"
      GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519" git push
    ''
  )

  # What these timers need that no switch can make, because it is a secret.
  # bin/doctor reads this list on the machine and says what is missing.
  {
    environment.etc."dotfiles/made-by-hand.json".text = builtins.toJSON {
      files =
        map
          (path: {
            inherit path;
            what = "The password of the Restic repositories.";
            how = "Write the password in it, on one line, then run: chmod 600 ${path}";
          })
          (lib.unique (lib.mapAttrsToList (_: backup: backup.passwordFile) config.services.restic.backups));

      # The remote of each repository, and the one sync-books copies to.
      rcloneRemotes = lib.unique (
        [ "gdrive" ]
        ++ lib.mapAttrsToList (
          _: backup: lib.elemAt (lib.splitString ":" backup.repository) 1
        ) config.services.restic.backups
      );
    };
  }
]
