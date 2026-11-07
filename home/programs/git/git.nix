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
  # config with nothing to copy. A profile may include other profiles (the
  # personal one picks an identity by folder), so every profile is linked.
  signingKey = host.git.signingKey or null;
  signingProgram = host.git.signingProgram or null;
  profile = user.git.profile or null;
  profiles = builtins.attrNames (builtins.readDir ./profiles);

  # Git skips an include it can't find, so a typo in the profile name must
  # fail here instead.
  profileInclude = lib.optional (profile != null) (
    lib.throwIfNot (builtins.pathExists (./profiles + "/${profile}.ini"))
      "config/users.nix: git.profile \"${profile}\" has no home/programs/git/profiles/${profile}.ini"
      "~/.config/git/profiles/${profile}.ini"
  );

  settings = {
    include.path = [ "~/.config/git/common.ini" ] ++ profileInclude;
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
  }
  // lib.genAttrs (map (f: "git/profiles/${f}") profiles) (f: mkSymlink (lib.removePrefix "git/" f));
}
