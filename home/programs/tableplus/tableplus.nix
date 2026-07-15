{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
    with pkgs;
    [
      tableplus
    ]
  );

  # ── Environment Variables ─────────────────────────────────────────────
  # home.sessionVariables = {
  #   EXAMPLE_VAR = "value";
  #   EDITOR = "${pkgs.tableplus}/bin/tableplus";
  # };

  # ── Shell Integration (zsh) ──────────────────────────────────────────
  # programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
  #   # source extra shell config, completions, etc.
  #   # eval $(${pkgs.tableplus}/bin/tableplus init zsh)
  # '';

  # ── Symlinked Config Files ───────────────────────────────────────────
  # home.file.".config/tableplus" = mkSymlink "config";
  # xdg.configFile."tableplus/config" = mkSymlink "config";
  # xdg.configFile."tableplus/config.toml" = mkSymlink "config.toml";

  # ── Fetch from GitHub ────────────────────────────────────────────────
  # home.file.".tableplus/plugins/example-plugin" = {
  #   source = pkgs.fetchFromGitHub {
  #     owner = "owner";
  #     repo = "repo";
  #     rev = "v1.0.0";
  #     sha256 = "";
  #   };
  # };

  # ── GNOME / dconf Integration ────────────────────────────────────────
  # dconf.settings = lib.mkIf config.dotfiles.programs.gnome.enable {
  #   "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
  #     name = "Tableplus";
  #     command = "tableplus";
  #     binding = "<Super>F1";
  #   };
  # };
}
