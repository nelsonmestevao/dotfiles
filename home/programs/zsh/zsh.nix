{
  config,
  lib,
  pkgs,
  ...
}:
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
  # oh-my-zsh sets up completion with compinit. Home Manager and /etc/zshrc
  # would each run compinit too, before it, which only slows the shell down.
  # This turns Home Manager's run off; system/nixos.nix and system/darwin.nix
  # turn off the one in /etc/zshrc.
  programs.zsh.enableCompletion = false;
  # Saved to ~/.zsh_history, as before.
  programs.zsh.history.size = 100000;

  # oh-my-zsh and every plugin come from nixpkgs, so bin/update moves them.
  # ~/.zshrc runs in this order: the instant prompt, zshrc from the checkout,
  # oh-my-zsh (which runs compinit), the plugins below in list order, and
  # syntax highlighting last, after every widget exists.
  programs.zsh.oh-my-zsh = {
    enable = true;
    # fzf is not here: its program sets up its own key bindings (see fzf.nix).
    plugins = [
      "colored-man-pages"
      "command-not-found"
      "direnv"
      "docker-compose"
      "extract"
      "git"
      "gitignore"
      "mise"
      "mix"
      "zoxide"
    ];
  };
  # fzf-tab must come after compinit and before the plugins that wrap widgets.
  programs.zsh.plugins = [
    {
      name = "fzf-tab";
      src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
    }
    {
      name = "zsh-autopair";
      src = "${pkgs.zsh-autopair}/share/zsh/zsh-autopair";
      file = "autopair.zsh";
    }
    {
      name = "zsh-autosuggestions";
      src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    }
    {
      name = "powerlevel10k";
      src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
      file = "powerlevel10k.zsh-theme";
    }
  ];
  programs.zsh.syntaxHighlighting.enable = true;

  programs.zsh.initContent = lib.mkMerge [
    # Powerlevel10k's instant prompt draws the prompt at once while the rest
    # loads, so it goes first. Anything that asks for input goes above it.
    (lib.mkBefore ''
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '')
    # zshrc is sourced from the checkout, so an edit takes effect in a new
    # shell. It runs before oh-my-zsh (800), as it always has, so the mise
    # plugin wraps the command-not-found handler in handlers.zsh.
    (lib.mkOrder 790 "source ${lib.escapeShellArg "${config.dotfiles.directory}/home/programs/zsh/zshrc"}")
  ];
  programs.zsh.envExtra = ''
    export DOTFILES="${config.dotfiles.directory}"

    [[ -r "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
  '';

  home.file."./.zshenv" = {
    target = ".zshenv";
    force = true;
  };
}
