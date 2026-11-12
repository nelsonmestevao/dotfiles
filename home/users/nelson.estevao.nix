{
  enableFor,
  valueFor,
  ...
}:
{
  # Shells
  dotfiles.programs.zsh.enable = true;

  # Window Managers
  dotfiles.programs.aerospace.enable = true;

  # Terminals
  dotfiles.programs.cmux.enable = enableFor [ "Remote-Nelson-Estevao" ];
  dotfiles.programs.ghostty.enable = enableFor [ "desktop" ];
  dotfiles.programs.wezterm.enable = false;

  # Editors & IDEs
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.vscode.enable = enableFor [ "desktop" ];
  dotfiles.programs.zed.enable = enableFor [ "desktop" ];

  # Programming Languages
  dotfiles.programs.elixir.enable = true;
  dotfiles.programs.erlang.enable = true;

  # Dev Tools
  dotfiles.programs.bat.enable = true;
  dotfiles.programs.btop.enable = true;
  dotfiles.programs.claude.enable = true;
  dotfiles.programs.codex.enable = true;
  dotfiles.programs.colima.enable = true;
  dotfiles.programs.cpufetch.enable = true;
  dotfiles.programs.ctop.enable = true;
  dotfiles.programs.curl.enable = true;
  dotfiles.programs.cursor.enable = true;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.docker.enable = true;
  dotfiles.programs.eza.enable = true;
  dotfiles.programs.fastfetch.enable = true;
  dotfiles.programs.fd.enable = true;
  dotfiles.programs.figlet.enable = true;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.git.enable = true;
  # 1Password on this Mac holds the key that signs commits, and signs with
  # it. A host that isn't named here signs nothing.
  dotfiles.programs.git.signingKey = valueFor {
    "Remote-Nelson-Estevao" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLaSmNmQBu2OUMctje364/orYOTUwpIq/7V+az8b+dw";
  };
  dotfiles.programs.git.signingProgram = valueFor {
    "Remote-Nelson-Estevao" = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  };
  dotfiles.programs.glab.enable = true;
  dotfiles.programs.herdr-app.enable = enableFor [ "desktop" ];
  dotfiles.programs.httpie.enable = true;
  dotfiles.programs.hyperfine.enable = true;
  dotfiles.programs.jj.enable = true;
  dotfiles.programs.jq.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.onefetch.enable = true;
  dotfiles.programs.projectionist.enable = true;
  dotfiles.programs.ripgrep.enable = true;
  dotfiles.programs.shellcheck.enable = true;
  dotfiles.programs.shfmt.enable = true;
  dotfiles.programs.speedtest.enable = true;
  dotfiles.programs.unzip.enable = true;
  dotfiles.programs.wget.enable = true;
  dotfiles.programs.zoxide.enable = true;

  #dotfiles.packages.enable = true;
}
