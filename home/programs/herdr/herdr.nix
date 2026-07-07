{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    herdr
  ];

  # ── Environment Variables ─────────────────────────────────────────────
  # home.sessionVariables = {
  #   EXAMPLE_VAR = "value";
  #   EDITOR = "${pkgs.herdr}/bin/herdr";
  # };

  # ── Shell Integration (zsh) ──────────────────────────────────────────
  # programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
  #   # source extra shell config, completions, etc.
  #   # eval $(${pkgs.herdr}/bin/herdr init zsh)
  # '';

  # ── Symlinked Config Files ───────────────────────────────────────────
  # home.file.".config/herdr" = mkSymlink "config";
  # xdg.configFile."herdr/config" = mkSymlink "config";
  # xdg.configFile."herdr/config.toml" = mkSymlink "config.toml";

  # ── Fetch from GitHub ────────────────────────────────────────────────
  # home.file.".herdr/plugins/example-plugin" = {
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
  #     name = "Herdr";
  #     command = "herdr";
  #     binding = "<Super>F1";
  #   };
  # };
}
