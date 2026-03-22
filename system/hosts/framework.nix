{
  config,
  lib,
  pkgs,
  ...
}:
{
  dotfiles.modules.audio.enable = true;
  dotfiles.modules.boot.enable = true;
  dotfiles.modules.brave.enable = true;
  dotfiles.modules.discord.enable = true;
  dotfiles.modules.docker.enable = true;
  dotfiles.modules.fingerprint.enable = true;
  dotfiles.modules.flatpak.enable = true;
  dotfiles.modules.gnome.enable = true;
  dotfiles.modules.kdenlive.enable = true;
  dotfiles.modules.keybase.enable = true;
  dotfiles.modules.locale.enable = true;
  dotfiles.modules.networking.enable = true;
  dotfiles.modules.obs.enable = true;
  dotfiles.modules.printing.enable = true;
  dotfiles.modules.shotcut.enable = true;
  dotfiles.modules.slack.enable = true;
  dotfiles.modules.spotify.enable = true;
  dotfiles.modules.tailscale.enable = true;
  dotfiles.modules.virtualisation.enable = true;
  dotfiles.modules.vlc.enable = true;
}
