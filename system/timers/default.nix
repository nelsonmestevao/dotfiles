# Per-user timers (backups, syncs). Each user's timers live in ./<username>.nix.
# A host turns them on and picks which of its users get them:
#
#   dotfiles.modules.timers.enable = true;
#   dotfiles.modules.timers.users = [ "nelson" ];
#
# Every user file is imported on every NixOS host, so the set of modules never
# depends on config; each file only takes effect for the users picked here.
{
  config,
  lib,
  users,
  ...
}:
let
  cfg = config.dotfiles.modules.timers;

  # This host's users that have a timers file. A user without one gets none.
  usersWithTimers = lib.filter (username: builtins.pathExists ./${username}.nix) (
    lib.attrNames users
  );

  # The user's file as a module that only applies when the host picks the user.
  # It takes the same arguments as the file, because the module system only
  # passes the arguments a module names.
  timersFor =
    username:
    let
      timers = import ./${username}.nix username;
    in
    lib.mirrorFunctionArgs timers (args: {
      _file = ./${username}.nix;
      config = lib.mkIf (cfg.enable && lib.elem username cfg.users) (timers args);
    });
in
{
  imports = map timersFor usersWithTimers;

  options.dotfiles.modules.timers = {
    enable = lib.mkEnableOption "the timers of the users picked in `users`";
    users = lib.mkOption {
      type = lib.types.listOf (lib.types.enum usersWithTimers);
      default = [ ];
      example = [ "nelson" ];
      description = "This host's users whose timers (./<username>.nix) run here.";
    };
  };

  config.assertions = [
    {
      assertion = cfg.enable -> cfg.users != [ ];
      message = "dotfiles.modules.timers is enabled, but dotfiles.modules.timers.users is empty. Pick the users whose timers should run.";
    }
  ];
}
