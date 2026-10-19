{
  config,
  lib,
  pkgs,
  mkSymlink,
  username,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    claude-code
    # Voice mode requires SoX for audio recording
    sox
  ];

  # ── Symlinked Config Files ───────────────────────────────────────────
  home.file.".claude/skills" = lib.mkIf (username == "nelson") (mkSymlink "skills");

  # Claude Code saves settings.json atomically, writing a tmp file next to the
  # symlink target after resolving only one level. A home.file symlink resolves
  # into the read-only home-manager-files store dir, so link straight to the repo.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run mkdir -p $HOME/.claude
    run ln -sfn ${config.dotfiles.directory}/home/programs/claude/settings.json \
      $HOME/.claude/settings.json
  '';
}
