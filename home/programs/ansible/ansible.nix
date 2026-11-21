{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    ansible
  ];

  home.shellAliases = {
    a = "ansible";
    ac = "ansible-console";
    ap = "ansible-playbook";
  };
}
