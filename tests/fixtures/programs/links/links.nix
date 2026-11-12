# Links a file that is in its folder.
{ mkSymlink, ... }:
{
  home.file.".linked" = mkSymlink "linked.conf";
}
