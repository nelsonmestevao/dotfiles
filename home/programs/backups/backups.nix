{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
let
  home = config.home.homeDirectory;

  # The same backup goes to each repo, one repo per host. Every entry gets its
  # own restic-backups-<name> service and timer, plus a restic-<name> wrapper.
  resticRepos = {
    mega = "rclone:mega:Backups/restic/${hostname}.repo";
    mdrive = "rclone:mdrive:Backups/restic/${hostname}.repo";
    tpshare = "rclone:tpshare:G/backups/${hostname}.repo";
  };
in
{
  # These are systemd user units. They run only while my systemd user
  # instance does: from login to logout, or always with
  # `loginctl enable-linger`. A run missed in between starts at the next
  # login (Persistent). Start one by hand with `systemctl --user start <name>`
  # and read its log with `journalctl --user -u <name>`.
  platforms = [ "linux" ];

  # ── Restic ────────────────────────────────────────────────────────────
  # nixpkgs' restic finds rclone on its own, so the rclone repos need nothing
  # more on PATH.
  services.restic.enable = true;
  services.restic.backups = lib.mapAttrs (_name: repository: {
    inherit repository;
    passwordFile = "${config.xdg.configHome}/restic/restic.pw";
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
      "--exclude-file=${../restic/exclude.txt}"
      "--verbose"
    ];
    timerConfig = {
      OnCalendar = "Mon..Fri 17:00";
      Persistent = true;
    };
  }) resticRepos;

  # ── Jobs ──────────────────────────────────────────────────────────────
  # Each job puts the tools it needs on its PATH, so the script names them
  # plainly.
  systemd.user.services = {
    # A mirror, not a versioned backup: rclone sync deletes on the remote
    # what is gone from ~/Books.
    sync-books = {
      Unit.Description = "Mirror ~/Books to Google Drive";
      Service = {
        Type = "oneshot";
        Environment = [ "PATH=${lib.makeBinPath [ pkgs.rclone ]}" ];
        ExecStart = toString (
          pkgs.writeShellScript "sync-books" ''
            set -e
            rclone sync ~/Books gdrive:Backups/Calibre -v
          ''
        );
      };
    };

    backup-dbclient = {
      Unit.Description = "Commit and push the dbclient queries";
      Service = {
        Type = "oneshot";
        Environment = [
          "PATH=${
            lib.makeBinPath [
              pkgs.curl
              pkgs.git
              pkgs.openssh
            ]
          }"
        ];
        ExecStart = toString (
          pkgs.writeShellScript "backup-dbclient" ''
            set -e
            cd "$HOME/.dbclient/query" || exit 1
            git diff --quiet && exit 0
            git add --all
            git commit --no-verify --no-gpg-sign --message "$(curl -s https://whatthecommit.com/index.txt)"
            GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519" git push
          ''
        );
      };
    };
  };

  systemd.user.timers = {
    sync-books = {
      Unit.Description = "Mirror ~/Books to Google Drive";
      Timer = {
        OnCalendar = "Mon..Fri 18:00";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    backup-dbclient = {
      Unit.Description = "Commit and push the dbclient queries";
      Timer = {
        OnCalendar = "hourly";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
