{
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

  # fzf's two zsh files, each at the one spot where it works. They are the
  # same files `fzf --zsh` prints, read from the store with no extra process.
  programs.zsh.initContent = lib.mkMerge [
    # Tab: before oh-my-zsh, so fzf-tab loads after it and takes over Tab.
    (lib.mkBefore ''
      source ${pkgs.fzf}/share/fzf/completion.zsh
    '')
    # Ctrl-T, Ctrl-R, Alt-C: after oh-my-zsh, which binds Ctrl-R itself.
    (lib.mkAfter ''
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
    '')
  ];
}
