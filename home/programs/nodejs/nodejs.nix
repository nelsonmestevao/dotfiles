{
  config,
  lib,
  mkSymlink,
  ...
}:
{
  home.shellAliases = {
    n = "npm";
    nr = "npm run";
    nd = "npm run dev";
    nb = "npm run build";
    nbw = "npm run build:watch";
    ns = "npm run start";
    nl = "npm run lint";
    nf = "npm run format";
    nt = "npm run test";
    ntw = "npm run test:watch";
    nsb = "npm run storybook";
  };

  # Node itself comes from mise; this is what mise installs next to it.
  home.file.".default-npm-packages" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink ./default-npm-packages
  );
}
