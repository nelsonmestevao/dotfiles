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
    thunderbird
  ];

  # ── Environment Variables ─────────────────────────────────────────────
  # home.sessionVariables = {
  #   EXAMPLE_VAR = "value";
  #   EDITOR = "${pkgs.thunderbird}/bin/thunderbird";
  # };

  # ── Shell Integration (zsh) ──────────────────────────────────────────
  # programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
  #   # source extra shell config, completions, etc.
  #   # eval $(${pkgs.thunderbird}/bin/thunderbird init zsh)
  # '';

  # ── Symlinked Config Files ───────────────────────────────────────────
  # home.file.".config/thunderbird" = mkSymlink "config";
  # xdg.configFile."thunderbird/config" = mkSymlink "config";
  # xdg.configFile."thunderbird/config.toml" = mkSymlink "config.toml";

  # ── Fetch from GitHub ────────────────────────────────────────────────
  # home.file.".thunderbird/plugins/example-plugin" = {
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
  #     name = "Thunderbird";
  #     command = "thunderbird";
  #     binding = "<Super>F1";
  #   };
  # };
}
