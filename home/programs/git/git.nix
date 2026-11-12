{
  config,
  lib,
  pkgs,
  mkSymlink,
  username,
  ...
}:
let
  inherit (config.dotfiles.programs.git) signingKey signingProgram;

  # The user's identity is profiles/<username>.ini, included when it exists.
  profile = "profiles/${username}.ini";

  gitConfig = {
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
  # ── Settings ──────────────────────────────────────────────────────────
  # Keys differ per machine, so a user file picks one with `enableFor`.
  options.signingKey = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "~/.ssh/id_ed25519.pub";
    description = ''
      The SSH key that signs commits and tags: the public key, or the path of
      its file. Leave it out and nothing is signed.
    '';
  };

  options.signingProgram = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    description = ''
      The program that signs with the key, when it isn't ssh-keygen (1Password
      on a Mac).
    '';
  };

  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
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
  ];

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    eval $(${pkgs.gitleaks}/bin/gitleaks completion zsh)

    alias lg='lazygit'
  '';

  xdg.configFile = {
    # Generated from the settings above, not linked: it's the one git file
    # that differs per host. Everything it includes is still a link you can
    # edit in place.
    "git/config".text = lib.generators.toGitINI gitConfig;
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
