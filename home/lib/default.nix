{ config, lib, ... }:

let
  # The repo as the flake sees it. A path literal in any module of this repo,
  # like ./config, is a path inside it.
  root = ../..;
in
{
  options.dotfiles.directory = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.dotfiles";
    description = "Path to the dotfiles repository.";
  };

  # `mkSymlink ./config` links a file or folder next to the module. Every home
  # module can take it as an argument. The link points into the checkout at
  # config.dotfiles.directory, not into the store, so an edit takes effect
  # with no rebuild.
  #
  # The path is in the flake's copy of the repo. The part after `root`, like
  # home/programs/zsh/config, is where the file is in the checkout too.
  #
  # A link to a file that isn't in the repo would dangle, and the program
  # would run with no config and no error. So a missing file fails the build,
  # with its path in the message.
  config._module.args.mkSymlink =
    path:
    let
      relativePath = lib.removePrefix "./" (lib.path.removePrefix root path);
      targetPath = "${config.dotfiles.directory}/${relativePath}";
    in
    if !builtins.isPath path then
      throw "mkSymlink takes a path like ./config (no quotes), but got ${
        lib.generators.toPretty { } path
      }."
    else if !lib.path.hasPrefix root path then
      throw "mkSymlink: ${toString path} is not in this repo, so it can't be linked into the checkout."
    else if !builtins.pathExists path then
      throw "mkSymlink: ${relativePath} does not exist. Add it, and `git add` it: the flake only sees tracked files."
    else
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
}
