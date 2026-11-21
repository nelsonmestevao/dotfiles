{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    eza
  ];

  home.shellAliases.tree = "eza -T";
}
