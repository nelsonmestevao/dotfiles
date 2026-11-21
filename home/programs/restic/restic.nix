{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    restic
  ];

  # The backups, by repository: `mega snapshots`. NixOS installs each command
  # where the backup timers run, with the repository and the password set.
  home.shellAliases = {
    mega = "restic-mega";
    mdrive = "restic-mdrive";
    tpshare = "restic-tpshare";
  };

  # exclude.txt, next to this file, is what a backup leaves out. The backup
  # timers read it (system/timers/), so nothing links it into the home.
}
