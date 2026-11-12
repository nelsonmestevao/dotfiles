{
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

  # The key bindings and the completion come from oh-my-zsh's `fzf` plugin
  # (home/programs/zsh/plugins.zsh). It asks fzf itself for them (`fzf --zsh`),
  # so it works the same on NixOS, on macOS and on other distros. Sourcing
  # fzf's files here as well set everything up twice, in every script too.
}
