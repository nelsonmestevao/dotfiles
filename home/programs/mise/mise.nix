{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    mise
  ];

  home.shellAliases.mr = "mise run";
}
