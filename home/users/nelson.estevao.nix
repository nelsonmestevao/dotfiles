{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
let
  enableFor = hosts: lib.elem hostname hosts;
  disableFor = hosts: !lib.elem hostname hosts;
in
{
  # Shells
  dotfiles.programs.zsh.enable = true;

  # Terminals
  dotfiles.programs.ghostty.enable = enableFor [
    "framework"
    "Remote-Nelson-Estevao"
  ];
  dotfiles.programs.wezterm.enable = false;

  # Editors & IDEs
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.vscode.enable = enableFor [
    "framework"
    "Remote-Nelson-Estevao"
  ];

  # Programming Languages
  dotfiles.programs.elixir.enable = true;
  dotfiles.programs.erlang.enable = true;

  # Dev Tools
  dotfiles.programs.bat.enable = true;
  dotfiles.programs.btop.enable = true;
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
  dotfiles.programs.herdr.enable = true;
  dotfiles.programs.httpie.enable = true;
  dotfiles.programs.hyperfine.enable = true;
  dotfiles.programs.jj.enable = true;
  dotfiles.programs.jq.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.onefetch.enable = true;
  dotfiles.programs.ripgrep.enable = true;
  dotfiles.programs.shellcheck.enable = true;
  dotfiles.programs.shfmt.enable = true;
  dotfiles.programs.speedtest.enable = true;
  dotfiles.programs.unzip.enable = true;
  dotfiles.programs.wget.enable = true;
  dotfiles.programs.zoxide.enable = true;

  #dotfiles.packages.enable = true;
}
