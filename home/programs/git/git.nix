{
  config,
  lib,
  pkgs,
  mkSymlink,
  username,
  ...
}:
let
  inherit (config.dotfiles.programs.git) signingKey signingProgram diffTools;

  # The user's identity is profiles/<username>.ini, included when it exists.
  profile = "profiles/${username}.ini";

  gitConfig = {
    include.path = [
      "~/.config/git/common.ini"
    ]
    ++ lib.optional diffTools "~/.config/git/diff-tools.ini"
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
  # Keys differ per machine, so a user file picks one with `valueFor`.
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

  # Off by default: the tools come to about 640 MB. A user file turns it on
  # for the hosts that should have them.
  options.diffTools = lib.mkEnableOption "readable diffs of pictures, documents and spreadsheets, with the tools they need (see diff-tools.ini)";

  # ── Packages ──────────────────────────────────────────────────────────
  home.packages =
    with pkgs;
    [
      delta
      difftastic
      gh
      git
      git-lfs
      git-who
      gitleaks
      lazygit
    ]
    # What the drivers in diff-tools.ini run.
    ++ lib.optionals diffTools [
      catdoc
      chafa
      exiftool
      pandoc
      xlsx2csv
    ];

  # gitleaks ships its own zsh completion, so nothing is set up for it here.
  home.shellAliases = {
    lg = "lazygit";

    # To the top folder of the repo.
    "g-" = ''cd $(git rev-parse --show-toplevel || echo ".")'';
    # Back to the worktree picked from a list.
    wt = ''dir=$(git worktree-select) && [ -n "$dir" ] && cd "$dir"'';

    grw = "git-review";
    ght = "git-history";

    # Rebase on the newest main or develop. git_main_branch and
    # git_develop_branch come from oh-my-zsh's git plugin.
    grbma = "git fetch origin; git fetch origin --prune; git rebase origin/$(git_main_branch)";
    grbfma = "git fetch fork; git fetch fork --prune; git rebase fork/$(git_main_branch)";
    grbdv = "git fetch origin; git fetch origin --prune; git rebase origin/$(git_develop_branch)";

    # The TODO lines that I wrote.
    todo = ''git grep -l TODO | xargs -n1 git blame -f -n -w | grep "$(git config user.name)" | grep TODO | sed "s/.\{9\}//" | sed "s/(.*)[[:space:]]*//"'';
  };

  xdg.configFile = {
    # Generated from the settings above, not linked: it's the one git file
    # that differs per host. Everything it includes is still a link you can
    # edit in place.
    "git/config".text = lib.generators.toGitINI gitConfig;
    "git/common.ini" = mkSymlink ./common.ini;
    # Included only where `diffTools` is on.
    "git/diff-tools.ini" = mkSymlink ./diff-tools.ini;
    "git/allowed_signers" = mkSymlink ./allowed_signers;
    "git/commit-template" = mkSymlink ./commit-template;
    "git/ignore" = mkSymlink ./ignore;
    "git/attributes" = mkSymlink ./attributes;
    # The whole folder, so a profile may include another and a new one needs
    # no rebuild. `force` lets the link replace the folder of per-file links
    # that earlier generations made.
    "git/profiles" = mkSymlink ./profiles // {
      force = true;
    };
  };
}
