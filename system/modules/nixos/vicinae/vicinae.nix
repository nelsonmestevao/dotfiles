{ ... }:
{
  # vicinae's input server needs a setuid helper to grab input devices.
  # Upstream's NixOS module makes that helper; lib/mkNixosConfig.nix imports
  # it. The launcher itself is set up in the home (programs.vicinae).
  programs.vicinae.input-server.enable = true;
}
