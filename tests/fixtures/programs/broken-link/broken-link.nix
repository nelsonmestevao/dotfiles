# Links a file that is not in its folder, which must fail the build.
{ mkSymlink, ... }:
{
  home.file.".missing" = mkSymlink "not-here.conf";
}
