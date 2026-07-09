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
    eza
  ];

  # ── Environment Variables ─────────────────────────────────────────────
  # home.sessionVariables = {
  #   EXAMPLE_VAR = "value";
  #   EDITOR = "${pkgs.eza}/bin/eza";
  # };

  # ── Shell Integration (zsh) ──────────────────────────────────────────
  # programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
  #   # source extra shell config, completions, etc.
  #   # eval $(${pkgs.eza}/bin/eza init zsh)
  # '';

  # ── Symlinked Config Files ───────────────────────────────────────────
  # home.file.".config/eza" = mkSymlink "config";
  # xdg.configFile."eza/config" = mkSymlink "config";
  # xdg.configFile."eza/config.toml" = mkSymlink "config.toml";

  # ── Fetch from GitHub ────────────────────────────────────────────────
  # home.file.".eza/plugins/example-plugin" = {
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
  #     name = "Eza";
  #     command = "eza";
  #     binding = "<Super>F1";
  #   };
  # };
}
