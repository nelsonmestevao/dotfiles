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
  # nelson.estevao (Darwin) uses a settings file with `apiKeyHelper` set;
  # every other user shares the base settings.json.
  home.file.".claude/settings.json" = mkSymlink "settings.json";
  home.file.".claude/skills" = mkSymlink "skills";
}
