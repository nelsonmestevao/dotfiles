{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    nix-search-tv
  ];

  # Search nixpkgs with fzf, with each package's details beside the list.
  home.shellAliases.pkgsearch = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";
}
