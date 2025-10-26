{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    fzf
  ];

  home.sessionVariables = {
    FZF_DEFAULT_COMMAND = "fd -t f .";
    FZF_CTRL_T_COMMAND = "fd .";
    FZF_ALT_C_COMMAND = "fd -t d . $HOME";

    FZF_DEFAULT_OPTS = "--height 50% --bind=ctrl-j:preview-down,ctrl-k:preview-up --reverse --inline-info --preview-window=right:60%";
  };

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    source "$(fzf-share)/key-bindings.zsh"
    source "$(fzf-share)/completion.zsh"
  '';
}
