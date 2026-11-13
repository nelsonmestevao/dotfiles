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
  # oh-my-zsh sets up completion with compinit (see theme.zsh). Home Manager
  # and /etc/zshrc would each run compinit too, before it, which only slows
  # the shell down. This turns Home Manager's run off; system/nixos.nix and
  # system/darwin.nix turn off the one in /etc/zshrc.
  programs.zsh.enableCompletion = false;
  # Saved to ~/.zsh_history, as before.
  programs.zsh.history.size = 100000;
  programs.zsh.initContent = builtins.readFile ./zshrc;
  programs.zsh.envExtra = ''
    export DOTFILES="${config.dotfiles.directory}"

    [[ -r "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
  '';

  home.file."./.zshenv" = {
    target = ".zshenv";
    force = true;
  };

  home.activation.cloneOhMyZsh = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
      ${pkgs.git}/bin/git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    fi
  '';

  home.file = {
    # Plugins
    ".oh-my-zsh/custom/plugins/zsh-autosuggestions" = {
      source = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-autosuggestions";
        rev = "v0.7.1";
        sha256 = "sha256-vpTyYq9ZgfgdDsWzjxVAE7FZH4MALMNZIFyEOBLm5Qo=";
      };
    };

    ".oh-my-zsh/custom/plugins/zsh-syntax-highlighting" = {
      source = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-syntax-highlighting";
        rev = "0.8.0";
        sha256 = "sha256-iJdWopZwHpSyYl5/FQXEW7gl/SrKaYDEtTH9cGP7iPo=";
      };
    };

    ".oh-my-zsh/custom/plugins/zsh-autopair" = {
      source = pkgs.fetchFromGitHub {
        owner = "hlissner";
        repo = "zsh-autopair";
        rev = "v1.0";
        sha256 = "sha256-wd/6x2p5QOSFqWYgQ1BTYBUGNR06Pr2viGjV/JqoG8A=";
      };
    };

    ".oh-my-zsh/custom/plugins/fzf-tab" = {
      source = pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = "fzf-tab";
        rev = "v1.3.0";
        sha256 = "sha256-8atbysoOyCBW2OYKmdc91x9V/Mk3eyg3hvzvhJpQ32w=";
      };
    };

    # Themes

    ".oh-my-zsh/custom/themes/powerlevel10k" = {
      source = pkgs.fetchFromGitHub {
        owner = "romkatv";
        repo = "powerlevel10k";
        rev = "v1.20.0";
        sha256 = "sha256-ES5vJXHjAKw/VHjWs8Au/3R+/aotSbY7PWnWAMzCR8E=";
      };
    };
  };
}
