{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    eza
  ];

  # `ls` stays the system's own: eza reads some of its flags another way.
  home.shellAliases.tree = "eza -T";
}
