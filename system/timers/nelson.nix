username:
{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:
let
  timers = import ../lib/mkSystemTimers.nix { inherit lib pkgs username; };

  inherit (config.users.users.${username}) home;

  # The same backup goes to each repo, one repo per host. Every entry gets its
  # own restic-backups-<name> service and timer, plus a restic-<name> wrapper.
  resticRepos = {
    mega = "rclone:mega:Backups/restic/${hostname}.repo";
    mdrive = "rclone:mdrive:Backups/restic/${hostname}.repo";
    tpshare = "rclone:tpshare:G/backups/${hostname}.repo";
  };
in
timers {
  sync-books = {
    at = "Mon..Fri 18:00";
    script = ''
      ${pkgs.rclone}/bin/rclone sync ~/Books gdrive:Backups/Calibre -v
    '';
  };

  backup-dbclient = {
    at = "hourly";
    script = ''
      cd $HOME/.dbclient/query || exit 1
      ${pkgs.git}/bin/git diff --quiet && exit 0
      ${pkgs.git}/bin/git add --all
      ${pkgs.git}/bin/git commit --no-verify --no-gpg-sign --message "$(${pkgs.curl}/bin/curl -s https://whatthecommit.com/index.txt)"
      GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i $HOME/.ssh/id_ed25519" ${pkgs.git}/bin/git push
    '';
  };
}
// {
  services.restic.backups = lib.mapAttrs (_name: repository: {
    inherit repository;
    user = username;
    passwordFile = "${home}/.config/restic/restic.pw";
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
    timerConfig = {
      OnCalendar = "Mon..Fri 17:00";
      Persistent = true;
    };
  }) resticRepos;
}
