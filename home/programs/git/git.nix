{
  config,
  lib,
  pkgs,
  mkSymlink,
  enableFor,
  host,
  user,
  ...
}:
let
  # The host says what signs commits here; the user says which profile to
  # include. Both come from config/, so a new host or user gets a working git
  # config with nothing to copy.
  signingKey = host.git.signingKey or null;
  signingProgram = host.git.signingProgram or null;
  profile = user.git.profile or null;

  # Every profile is linked, since a profile may include another one (the
  # personal one picks an identity by folder). The user's must exist.
  profiles = lib.attrNames (
    lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".ini" name) (
      builtins.readDir ./profiles
    )
  );
  profileFile = "${profile}.ini";

  # Later settings win in git, and includes are read in place, so the shared
  # file goes first and the profile can override it.
  includes = [
    "~/.config/git/common.ini"
  ]
  ++ lib.optional (profile != null) "~/.config/git/profiles/${profile}.ini";

  signing = lib.optionalAttrs (signingKey != null) {
    user.signingkey = signingKey;
    gpg = {
      format = "ssh";
      ssh = {
        allowedSignersFile = "~/.config/git/allowed_signers";
      }
      // lib.optionalAttrs (signingProgram != null) { program = signingProgram; };
    };
    commit.gpgsign = true;
    tag.gpgsign = true;
  };
in
lib.throwIfNot (profile == null || lib.elem profileFile profiles)
  "config/users.nix: git.profile \"${toString profile}\" has no home/programs/git/profiles/${profileFile}"
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
      #GIT_FUZZY_PATH_DIR="$HOME/.git-fuzzy"
      #execute "git clone https://github.com/bigH/git-fuzzy.git $GIT_FUZZY_PATH_DIR" "Cloning Git Fuzzy..."
      #execute "git -C $GIT_FUZZY_PATH_DIR pull" "Updating Git Fuzzy..."

      # export PATH="$HOME/.git-fuzzy/bin:$PATH";
      eval $(${pkgs.gitleaks}/bin/gitleaks completion zsh)

      alias lg='lazygit'
    '';

    xdg.configFile = {
      # Generated from config/, not linked: it's the one git file that differs
      # per host. Everything it includes is still a link you can edit in place.
      "git/config".text = lib.generators.toGitINI ({ include.path = includes; } // signing);
      "git/common.ini" = mkSymlink "common.ini";
      "git/allowed_signers" = mkSymlink "allowed_signers";
      "git/commit-template" = mkSymlink "commit-template";
      "git/ignore" = mkSymlink "ignore";
      "git/attributes" = mkSymlink "attributes";
    }
    // lib.listToAttrs (
      map (f: lib.nameValuePair "git/profiles/${f}" (mkSymlink "profiles/${f}")) profiles
    );
  }
