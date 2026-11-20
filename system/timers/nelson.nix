username:
{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:
let
  mkSystemTimer = import ../lib/mkSystemTimer.nix {
    inherit pkgs username;
  };

  inherit (config.users.users.${username}) home;

  # The same backup goes to each repo, one repo per host. Every entry gets its
  # own restic-backups-<name> service and timer, plus a restic-<name> wrapper.
  # Each repo has its own hour, so the three don't read the disk at once.
  resticRepos = {
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

  passwordFile = "${home}/.config/restic/restic.pw";

  # Every backup unit. Each one tells the desktop when it fails.
  resticUnits = map (name: "restic-backups-${name}") (lib.attrNames resticRepos);
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

  {
    services.restic.backups = lib.mapAttrs (_name: repo: {
      inherit (repo) repository;
      inherit passwordFile;
      user = username;
      paths = map (dir: "${home}/${dir}") [
        "Archive"
        "Books"
        "Code"
        "Documents"
        "Downloads"
        "Pictures"
        "Videos"
      ];
      extraBackupArgs = [
        "--compression=max"
        "--exclude-file=${../../home/programs/restic/exclude.txt}"
        "--verbose"
      ];
      # After each backup, keep a week of daily snapshots, five weekly ones
      # and twelve monthly ones, and delete the rest. Without this a repo
      # grows forever.
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
      # Then read a random hundredth of the repo back and check it. A backup
      # that can't be read is no backup, and a week of these reads about a
      # twentieth. The README has the restore drill, which no timer can do
      # for you. systemd reads a lone % as the start of a specifier, so 1%
      # is written 1%%.
      checkOpts = [ "--read-data-subset=1%%" ];
      timerConfig = {
        OnCalendar = repo.backupAt;
        Persistent = true;
      };
    }) resticRepos;
  }

  # A failed backup shows a notice on the desktop, like any other timer (see
  # ./default.nix).
  {
    systemd.services = lib.genAttrs resticUnits (_: {
      unitConfig.OnFailure = "notify-failure@%N.service";
    });
  }

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
