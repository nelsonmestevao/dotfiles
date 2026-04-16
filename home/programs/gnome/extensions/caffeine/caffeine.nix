{ pkgs, ... }:
{
  # I want v59 at least to be able to use CLI tools
  package = pkgs.unstable.gnomeExtensions.caffeine;
}
