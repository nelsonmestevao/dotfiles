{
  config,
  lib,
  pkgs,
  mkSymlink,
  enableFor,
  host,
  username,
  ...
}:
let
  # The host says what signs commits here, from config/hosts.nix. The user's
  # identity is profiles/<username>.ini, included when it exists.
  signingKey = host.git.signingKey or null;
  signingProgram = host.git.signingProgram or null;
  profile = "profiles/${username}.ini";

  settings = {
    include.path = [
      "~/.config/git/common.ini"
    ]
    ++ lib.optional (builtins.pathExists (./. + "/${profile}")) "~/.config/git/${profile}";
  }
  // lib.optionalAttrs (signingKey != null) {
    user.signingkey = signingKey;
    commit.gpgsign = true;
    tag.gpgsign = true;
  }
  // lib.optionalAttrs (signingProgram != null) {
    gpg.ssh.program = signingProgram;
  };
in
{
  home.packages =
    with pkgs;
    [
      delta
      diffpdf
      difftastic
      gh
      git
      git-lfs
      git-who
      gitleaks
      glab
      lazygit
    ]
    ++ lib.optionals (enableFor [ "framework" ]) [
      (callPackage ./git-sim/package.nix { })
    ];

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    eval $(${pkgs.gitleaks}/bin/gitleaks completion zsh)

    alias lg='lazygit'
  '';

  xdg.configFile = {
    # Generated from config/, not linked: it's the one git file that differs
    # per host. Everything it includes is still a link you can edit in place.
    "git/config".text = lib.generators.toGitINI settings;
    "git/common.ini" = mkSymlink "common.ini";
    "git/allowed_signers" = mkSymlink "allowed_signers";
    "git/commit-template" = mkSymlink "commit-template";
    "git/ignore" = mkSymlink "ignore";
    "git/attributes" = mkSymlink "attributes";
    # The whole folder, so a profile may include another and a new one needs
    # no rebuild. `force` lets the link replace the folder of per-file links
    # that earlier generations made.
    "git/profiles" = mkSymlink "profiles" // {
      force = true;
    };
  };
}
