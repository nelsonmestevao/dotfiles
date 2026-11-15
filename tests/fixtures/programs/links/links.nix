# Links a file and a folder that are in its folder.
{ mkSymlink, ... }:
{
  home.file.".linked" = mkSymlink ./linked.conf;
  home.file.".linked-folder" = mkSymlink ./folder // {
    force = true;
  };
}
