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
    diffpdf
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

  xdg.configFile = {
    "git/config" = mkSymlink "gitconfig";
    "git/allowed_signers" = mkSymlink "allowed_signers";
    "git/commit-template" = mkSymlink "git-commit-msg-template";
    "git/ignore" = mkSymlink "gitignore";
    "git/attributes" = mkSymlink "gitattributes";
    "git/profiles/personal.ini" = mkSymlink "personal.ini";
    "git/profiles/uminho.ini" = mkSymlink "uminho.ini";
    "git/profiles/marmela.ini" = mkSymlink "marmela.ini";
  };
}
