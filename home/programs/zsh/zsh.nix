{
  config,
  lib,
  pkgs,
  ...
}:
let
  # oh-my-zsh's custom folder, built from nixpkgs so bin/update moves the
  # plugins and the theme with everything else.
  ohMyZshCustom = pkgs.linkFarm "oh-my-zsh-custom" {
    "plugins/fzf-tab" = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
    "plugins/zsh-autosuggestions" = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    # These two ship no .plugin.zsh file, so their main file gets that name.
    "plugins/zsh-autopair/zsh-autopair.plugin.zsh" =
      "${pkgs.zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh";
    "plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh" =
      "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
    "themes/powerlevel10k" = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
  };
in
{
  # On a machine you reach over SSH, the prompt says which one it is.
  options.showHost = lib.mkEnableOption "the host name in the prompt";

  home.packages = with pkgs; [
    zsh
    # Completion for nix-build, nix-shell and the like. Home Manager added it
    # while its own compinit was on.
    (lib.lowPrio nix-zsh-completions)
  ];

  home.sessionVariables = {
    SHELL = "${pkgs.zsh}/bin/zsh";
    DOTFILES = config.dotfiles.directory;
    PROMPT_SHOW_HOST = lib.mkIf config.dotfiles.programs.zsh.showHost "1";
  };

  programs.zsh.enable = true;
  # oh-my-zsh sets up completion with compinit (see theme.zsh). Home Manager
  # and /etc/zshrc would each run compinit too, before it, which only slows
  # the shell down. This turns Home Manager's run off; system/nixos.nix and
  # system/darwin.nix turn off the one in /etc/zshrc.
  programs.zsh.enableCompletion = false;
  # Saved to ~/.zsh_history, as before.
  programs.zsh.history.size = 100000;
  # ~/.zshrc sets the store paths, then sources zshrc from the checkout, so an
  # edit takes effect in a new shell. The paths aren't session variables, so a
  # tmux started before a switch still gets the new ones.
  programs.zsh.initContent = ''
    export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
    ZSH_CUSTOM="${ohMyZshCustom}"
    source ${lib.escapeShellArg "${config.dotfiles.directory}/home/programs/zsh/zshrc"}
  '';
  programs.zsh.envExtra = ''
    [[ -r "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
  '';

  home.file."./.zshenv" = {
    target = ".zshenv";
    force = true;
  };
}
