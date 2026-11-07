{
  mkSymlink,
  ...
}:
{
  platforms = [ "darwin" ];

  # The app itself comes from Homebrew (system/modules/darwin/homebrew).
  xdg.configFile."aerospace/aerospace.toml" = mkSymlink "aerospace.toml";
}
