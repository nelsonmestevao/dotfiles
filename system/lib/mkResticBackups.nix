# Restic backups of `username`'s folders, the same ones to each repository:
#
#   mkResticBackups {
#     passwordFile = "/home/me/.config/restic/restic.pw";
#     exclude = ./exclude.txt;
#     paths = [ "/home/me/Documents" ];
#     keep = { daily = 7; weekly = 5; monthly = 12; };
#     repos.mega = {
#       repository = "rclone:mega:Backups/me.repo";
#       backupAt = "Mon..Fri 17:00";
#     };
#   }
#
# Each repository gets a restic-backups-<name> service and timer, and a
# restic-<name> command that carries the repository and the password, for
# `restic-mega snapshots` and the like.
{ lib, username }:
{
  # The file with the repositories' password. Made by hand: see bin/doctor.
  passwordFile,
  # A file of patterns to leave out.
  exclude,
  # The folders to back up.
  paths,
  # How many snapshots stay after each backup, like { daily = 7; }.
  keep,
  # The repositories, by name, each with `repository` and `backupAt`.
  repos,
}:
{
  services.restic.backups = lib.mapAttrs (_name: repo: {
    inherit (repo) repository;
    inherit passwordFile paths;
    user = username;
    extraBackupArgs = [
      "--compression=max"
      "--exclude-file=${exclude}"
      "--verbose"
    ];
    # After each backup, delete the snapshots `keep` doesn't name. Without
    # this a repository grows forever.
    pruneOpts = lib.mapAttrsToList (period: count: "--keep-${period} ${toString count}") keep;
    # Then read a random hundredth of the repository back and check it. A
    # backup that can't be read is no backup, and a week of these reads about
    # a twentieth. systemd reads a lone % as the start of a specifier, so 1%
    # is written 1%%.
    checkOpts = [ "--read-data-subset=1%%" ];
    timerConfig = {
      OnCalendar = repo.backupAt;
      Persistent = true;
    };
  }) repos;

  # Tell the user on the desktop when a backup fails (see
  # ../timers/default.nix).
  systemd.services = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "restic-backups-${name}" {
      unitConfig.OnFailure = "notify-failure@%N.service";
    }
  ) repos;
}
