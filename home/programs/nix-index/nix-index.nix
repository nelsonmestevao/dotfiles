{
  ...
}:
{
  # Which package has which command. The index comes ready-made from the
  # nix-index-database flake (see lib/mkHomeConfig.nix), so nothing indexes
  # nixpkgs on this machine. `nix-locate bin/cowsay` asks it.
  programs.nix-index.enable = true;

  # zsh has its own "command not found" in home/programs/zsh/handlers.zsh,
  # which asks nix-locate itself. Home Manager's would replace it.
  programs.nix-index.enableZshIntegration = false;

  # `, cowsay hi` runs a command once, without installing it.
  programs.nix-index-database.comma.enable = true;
}
