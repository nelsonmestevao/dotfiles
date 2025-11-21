{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    zsh
  ];

  home.sessionVariables = {
    SHELL = "${pkgs.zsh}/bin/zsh";
  };

  programs.zsh.enable = true;
  # programs.zsh.initContent = builtins.readFile ./zshrc;

  home.file.".zshrc" = mkSymlink "zshrc";

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

    ".oh-my-zsh/custom/plugins/zsh-vi-mode" = {
      source = pkgs.fetchFromGitHub {
        owner = "jeffreytse";
        repo = "zsh-vi-mode";
        rev = "v0.12.0";
        sha256 = "sha256-EYr/jInRGZSDZj+QVAc9uLJdkKymx1tjuFBWgpsaCFw=";
      };
    };

    ".oh-my-zsh/custom/plugins/fzf-tab" = {
      source = pkgs.fetchFromGitHub {
        owner = "Aloxaf";
        repo = "fzf-tab";
        rev = "v1.2.0";
        sha256 = "sha256-q26XVS/LcyZPRqDNwKKA9exgBByE0muyuNb0Bbar2lY=";
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
