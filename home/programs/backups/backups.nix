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
  # User units: they run only while I'm logged in (see the README).
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
      # The checkout's file, so an edit counts on the next run.
      "--exclude-file=${config.dotfiles.directory}/home/programs/restic/exclude.txt"
      "--verbose"
    ];
    # A user unit can't wait for network-online.target, so wait for it here.
    backupPrepareCommand = "${lib.getExe' pkgs.networkmanager "nm-online"} -q -t 60 || true";
    timerConfig = {
      OnCalendar = "Mon..Fri 17:00";
      Persistent = true;
    };
  }) resticRepos;

  # ── Jobs ──────────────────────────────────────────────────────────────
  systemd.user.services =
    # Like NixOS: a rebuild doesn't restart a backup that is running.
    lib.mapAttrs' (
      name: _:
      lib.nameValuePair "restic-backups-${name}" { Service.X-RestartIfChanged = lib.mkForce false; }
    ) resticRepos
    // {
      # A mirror, not a versioned backup: rclone sync deletes on the remote
      # what is gone from ~/Books.
      sync-books = {
        Unit.Description = "Mirror ~/Books to Google Drive";
        Service.Type = "oneshot";
        Service.ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "sync-books";
            runtimeInputs = [ pkgs.rclone ];
            text = "rclone sync ~/Books gdrive:Backups/Calibre -v";
          }
        );
      };

      backup-dbclient = {
        Unit.Description = "Commit and push the dbclient queries";
        Service.Type = "oneshot";
        Service.ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "backup-dbclient";
            runtimeInputs = [
              pkgs.curl
              pkgs.git
              pkgs.openssh
            ];
            text = ''
              cd "$HOME/.dbclient/query" || exit 1
              git diff --quiet && exit 0
              git add --all
              git commit --no-verify --no-gpg-sign --message "$(curl -s https://whatthecommit.com/index.txt)"
              GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519" git push
            '';
          }
        );
      };
    };

  systemd.user.timers =
    lib.mapAttrs
      (_: OnCalendar: {
        Timer = {
          inherit OnCalendar;
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      })
      {
        sync-books = "Mon..Fri 18:00";
        backup-dbclient = "hourly";
      };
}
