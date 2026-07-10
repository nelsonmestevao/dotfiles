{
  config,
  lib,
  pkgs,
  hostname,
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

    alias lg='lazygit'
  '';

  xdg.configFile = {
    "git/config" = mkSymlink "hosts/${hostname}.ini";
    "git/common.ini" = mkSymlink "common.ini";
    "git/allowed_signers" = mkSymlink "allowed_signers";
    "git/commit-template" = mkSymlink "commit-template";
    "git/ignore" = mkSymlink "ignore";
    "git/attributes" = mkSymlink "attributes";
  }
  // lib.listToAttrs (
    map (p: lib.nameValuePair "git/profiles/${p}.ini" (mkSymlink "profiles/${p}.ini")) [
      "personal"
      "uminho"
      "marmela"
    ]
  );
}
