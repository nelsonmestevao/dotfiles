{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.programs.latex;
in
{
  options.dotfiles.programs.latex = {
    enable = lib.mkEnableOption "Enable LaTeX configuration.";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      texliveFull
    ];

    home.file.".latexmkrc" = config.lib.dotfiles.mkSymlink "nixos/home/programs/latex/latexmkrc";
  };
}
