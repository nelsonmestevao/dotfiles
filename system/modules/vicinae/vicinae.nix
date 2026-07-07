{
  config,
  lib,
  pkgs,
  vicinae,
  ...
}:
# vicinae's global hotkey support needs a setuid helper to grab input
# devices. Splice in `vicinae.nixosModules.default` (a plain function that
# only sets `security.wrappers.vicinae-input-server`) so it tracks upstream
# while staying gated by `dotfiles.modules.vicinae.enable`. The launcher
# itself is configured on the home-manager side (programs.vicinae).
vicinae.nixosModules.default { inherit pkgs; }
