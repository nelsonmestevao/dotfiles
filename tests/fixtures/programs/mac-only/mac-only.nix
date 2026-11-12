# A program that only runs on a Mac.
{ ... }:
{
  platforms = [ "darwin" ];

  home.sessionVariables.MAC_ONLY = "on";
}
