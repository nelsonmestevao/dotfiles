{
  mkSymlink,
  ...
}:
{
  home.sessionVariables = {
    KERL_BUILD_DOCS = "yes";
    KERL_INSTALL_HTMLDOCS = "yes";
    KERL_INSTALL_MANPAGES = "yes";
  };

  xdg.configFile."rebar/rebar.config" = mkSymlink "rebar.config";
}
