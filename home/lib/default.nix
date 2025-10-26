{ config, lib, ... }:

{
  # Create true symlinks to files in the dotfiles repository.
  lib.dotfiles = {
    mkSymlinkFrom =
      dotfilesPath: relativePath:
      let
        targetPath = "${dotfilesPath}/${relativePath}";
      in
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
