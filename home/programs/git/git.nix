{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    delta
    difftastic
    gh
    git
    git-who
    gitleaks
    lazygit
  ];

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    #GIT_FUZZY_PATH_DIR="$HOME/.git-fuzzy"
    #execute "git clone https://github.com/bigH/git-fuzzy.git $GIT_FUZZY_PATH_DIR" "Cloning Git Fuzzy..."
    #execute "git -C $GIT_FUZZY_PATH_DIR pull" "Updating Git Fuzzy..."

    # export PATH="$HOME/.git-fuzzy/bin:$PATH";
    eval $(${pkgs.gitleaks}/bin/gitleaks completion zsh)
  '';

  home.file.".gitconfig" = mkSymlink "gitconfig";
}
