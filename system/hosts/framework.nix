{
  ...
}:
{
  # ── System ───────────────────────────────────────────────────────────
  dotfiles.modules.atd.enable = true;
  dotfiles.modules.boot.enable = true;
  dotfiles.modules.fingerprint.enable = true;
  dotfiles.modules.locale.enable = true;
  dotfiles.modules.printing.enable = true;
  dotfiles.modules.swap.enable = true;

  # ── Networking ───────────────────────────────────────────────────────
  dotfiles.modules.networking.enable = true;
  dotfiles.modules.tailscale.enable = true;

  # ── Desktop & Audio ──────────────────────────────────────────────────
  dotfiles.modules.audio.enable = true;
  dotfiles.modules.gnome.enable = true;
  dotfiles.modules.vicinae.enable = true;

  # ── Browsers ─────────────────────────────────────────────────────────
  dotfiles.modules.firefox.enable = true;

  # ── Communication ────────────────────────────────────────────────────
  dotfiles.modules.keybase.enable = true;

  # ── Packages & Virtualisation ────────────────────────────────────────
  dotfiles.modules.docker.enable = true;
  dotfiles.modules.flatpak.enable = true;
  dotfiles.modules.virtualisation.enable = true;
}
