{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    zoxide
  ];

  home.shellAliases = {
    j = "z";
    ji = "zi";
  };
}
