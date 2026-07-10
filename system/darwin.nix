{
  config,
  lib,
  pkgs,
  hostname,
  users,
  ...
}:
{
  imports = [
    ./hosts/${hostname}.nix
  ];

  # ── Nix ─────────────────────────────────────────────────────────────────
  # This machine runs Determinate Nix, which uses its own daemon to manage the
  # Nix installation and conflicts with nix-darwin's native management. Turning
  # nix-darwin's management off is required to coexist with Determinate.
  #
  # Consequence: nix-darwin's `nix.*` options (nix.settings, nix.gc, Linux
  # builder, …) become unavailable — Determinate owns them. Flakes and
  # nix-command are enabled by Determinate out of the box, and it handles GC.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  # ── Users ───────────────────────────────────────────────────────────────
  # Homebrew activation and user-scoped defaults run as the primary user.
  # macOS owns the account itself; we only point nix-darwin at it.
  system.primaryUser = lib.head (lib.attrNames users);

  # ── Shell ─────────────────────────────────────────────────────────────
  # Makes /etc/zshrc source the nix-darwin environment (PATH, profiles). The
  # zsh *configuration* still lives in home-manager.
  programs.zsh.enable = true;

  # Don't emit a bare `compinit` into /etc/zshrc. It runs before ~/.zshrc and,
  # once Homebrew's group-writable share/zsh/site-functions lands on fpath (via
  # `brew shellenv`), compaudit flags it as insecure and compinit interactively
  # prompts on every shell start. oh-my-zsh already runs `compinit -i`, which
  # silently skips insecure dirs, so the global call is redundant here.
  programs.zsh.enableGlobalCompInit = false;

  # ──────────────────────────────────────────────────────────────────────
  # Set to the nix-darwin version you first installed on this machine. A lower
  # value than the current release is fine; a higher one errors.
  system.stateVersion = 6;
}
