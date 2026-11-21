{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    mise
  ];

  home.shellAliases.mr = "mise run";

  # mise writes ~/.config/mise/config.toml itself, so the settings from here
  # go next to it, in conf.d, which mise reads too.
  xdg.configFile."mise/conf.d/dotfiles.toml" = mkSymlink ./settings.toml;
}
