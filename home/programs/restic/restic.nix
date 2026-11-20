{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    restic
  ];

  # exclude.txt, next to this file, is what a backup leaves out. The backup
  # timers read it (system/timers/), so nothing links it into the home.
}
