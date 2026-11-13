{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = [ pkgs.openssh ];

  home.file.".ssh/config" = mkSymlink "config";
}
