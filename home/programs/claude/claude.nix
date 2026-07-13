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
  ];

  # ── Symlinked Config Files ───────────────────────────────────────────
  # nelson.estevao (Darwin) uses a settings file with `apiKeyHelper` set;
  # every other user shares the base settings.json.
  home.file.".claude/settings.json" = mkSymlink (
    if username == "nelson.estevao" then "settings.remote.json" else "settings.json"
  );
  home.file.".claude/skills" = mkSymlink "skills";
}
