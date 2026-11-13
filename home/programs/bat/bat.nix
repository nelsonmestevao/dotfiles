{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.bat ];

  xdg.configFile."bat/config" = mkSymlink "config";

  # Only in a shell you type in. A script that calls `cat` gets the real one.
  home.shellAliases.cat = "bat -p";
}
