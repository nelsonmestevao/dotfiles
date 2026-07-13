{ ... }:
# vicinae's input-server needs a setuid helper to grab input devices. That
# security wrapper is provided by `vicinae.nixosModules.default`, imported in
# lib/mkNixosConfig.nix and gated on `dotfiles.modules.vicinae.enable` (wired
# up there). This file exists only so that enable flag gets registered; the
# launcher itself is configured on the home-manager side (programs.vicinae).
{ }
