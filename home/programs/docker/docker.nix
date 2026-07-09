{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages =
    with pkgs;
    [
      cup-docker
      docker-buildx
      docker-compose
      dockerfmt
      lazydocker
    ]
    # On Linux the docker CLI comes from the system daemon package
    # (virtualisation.docker), so only ship the standalone client here on
    # Darwin, where colima provides just the daemon.
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      docker-client
    ];

  # ── Environment Variables ─────────────────────────────────────────────
  # home.sessionVariables = {
  #   EXAMPLE_VAR = "value";
  #   EDITOR = "${pkgs.docker}/bin/docker";
  # };

  # ── Shell Integration (zsh) ──────────────────────────────────────────
  # programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
  #   # source extra shell config, completions, etc.
  #   # eval $(${pkgs.docker}/bin/docker init zsh)
  # '';

  # ── Symlinked Config Files ───────────────────────────────────────────
  # home.file.".config/docker" = mkSymlink "config";
  # xdg.configFile."docker/config" = mkSymlink "config";
  # xdg.configFile."docker/config.toml" = mkSymlink "config.toml";

  # ── Fetch from GitHub ────────────────────────────────────────────────
  # home.file.".docker/plugins/example-plugin" = {
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
  #     name = "Docker";
  #     command = "docker";
  #     binding = "<Super>F1";
  #   };
  # };
}
