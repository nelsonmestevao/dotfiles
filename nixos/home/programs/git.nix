{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../lib
  ];

  home.packages = with pkgs; [
    delta
    difftastic
    gh
    git
    git-who
    gitleaks
    jujutsu
    lazygit
  ];

  #GIT_FUZZY_PATH_DIR="$HOME/.git-fuzzy"
  #execute "git clone https://github.com/bigH/git-fuzzy.git $GIT_FUZZY_PATH_DIR" "Cloning Git Fuzzy..."
  #execute "git -C $GIT_FUZZY_PATH_DIR pull" "Updating Git Fuzzy..."

  home.file.".gitconfig" = config.lib.dotfiles.mkSymlink "nixos/home/programs/git/gitconfig";
}
