{ config, lib, ... }:

let
  # The repo as the flake sees it. A path literal in any module of this repo,
  # like ./config, is a path inside it.
  root = ../..;

  # Where a path in the flake's copy of the repo is in the checkout at
  # config.dotfiles.directory. The part after `root`, like
  # home/programs/zsh/zshrc, is the same in both. `helper` names the helper
  # that asked, for the messages.
  #
  # A file that isn't in the repo would leave a link that dangles or a script
  # that reads nothing, with no error. So a missing file fails the build, with
  # its path in the message.
  inCheckout =
    helper: path:
    if !builtins.isPath path then
      throw "${helper} takes a path like ./config (no quotes), but got ${
        lib.generators.toPretty { } path
      }."
    else if !lib.path.hasPrefix root path then
      throw "${helper}: ${toString path} is not in this repo, so it has no place in the checkout."
    else
      let
        relativePath = lib.removePrefix "./" (lib.path.removePrefix root path);
      in
      if !builtins.pathExists path then
        throw "${helper}: ${relativePath} does not exist. Add it, and `git add` it: the flake only sees tracked files."
      else
        "${config.dotfiles.directory}/${relativePath}";
in
{
  options.dotfiles.directory = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.dotfiles";
    description = "Path to the dotfiles repository.";
  };

  # Every home module can take these two as arguments.
  config._module.args = {
    # `checkoutPath ./mods` is where ./mods is in the checkout, as a string,
    # for an activation script that reads from the repo.
    checkoutPath = inCheckout "checkoutPath";

    # `mkSymlink ./config` links a file or folder from the repo. The link
    # points into the checkout, not into the store, so an edit takes effect
    # with no rebuild.
    mkSymlink =
      path:
      let
        target = inCheckout "mkSymlink" path;
        quoted = lib.escapeShellArg target;
      in
      # A wrong path stops the build here, not when the link is built.
      builtins.seq target {
        source = config.lib.file.mkOutOfStoreSymlink target;
        # Home Manager runs every onChange in one shell, so this sets no
        # variables.
        onChange = ''
          if [ ! -e ${quoted} ]; then
            printf "\033[1;33m⚠ Warning\033[0m: '%s' does not exist \033[1;31m✗\033[0m\n" ${quoted} >&2
          fi
        '';
      };
  };
}
