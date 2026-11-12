{ config, lib, ... }:

{
  options.dotfiles.directory = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.dotfiles";
    description = "Path to the dotfiles repository.";
  };

  config.lib.dotfiles = {
    # `mkSymlinkIn { owner; folder; } "file"` links a file that a module keeps
    # in `folder` (a path from the repo root, like "home/programs/zsh"). It is
    # a true link into the checkout, so an edit takes effect with no rebuild.
    # The module wrappers turn it into the `mkSymlink` each module gets.
    #
    # A link to a file that isn't in the repo would dangle, and the program
    # would run with no config and no error. So a missing file fails the
    # build, with `owner` (the module's option) in the message.
    mkSymlinkIn =
      { owner, folder }:
      relativePath:
      let
        targetPath = "${config.dotfiles.directory}/${folder}/${relativePath}";
      in
      lib.throwIfNot (builtins.pathExists (../.. + "/${folder}/${relativePath}"))
        "${owner}: ${folder}/${relativePath} does not exist"
        {
          source = config.lib.file.mkOutOfStoreSymlink targetPath;
          onChange = ''
            RED="\033[1;31m"
            YELLOW="\033[1;33m"
            GREEN="\033[1;32m"
            RESET="\033[0m"

            if [ ! -e "${targetPath}" ]; then
              echo -e "$YELLOW⚠ Warning$RESET: '${targetPath}' does not exist $RED✗$RESET" >&2
            fi
          '';
        };
  };
}
