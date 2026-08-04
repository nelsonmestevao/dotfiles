{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
let
  # weasyprint's font-rendering pixel tests render slightly differently on
  # darwin; the nixpkgs derivation already deselects several flaky ones but
  # misses test_unicode_range on this snapshot, so the build fails on macOS.
  # Deselect it there too, leaving the Linux build (and its binary cache) alone.
  weasyprint =
    if pkgs.stdenv.isDarwin then
      pkgs.python313Packages.weasyprint.overridePythonAttrs (old: {
        doCheck = false;
      })
    else
      pkgs.python313Packages.weasyprint;
in
{
  home.packages =
    with pkgs;
    [
      # elixir_1_18
      # erlang_27

      ## pdf documents
      # k2pdfopt
      pdftk
      weasyprint

      ## image processing and optimization
      file
      image_optim
      # gifsicle
      # jpegoptim
      # libwebp
      svgo
      # optipng
      # pngquant

      (pkgs.writeShellScriptBin "runex" ''
        FILE="$1"
        TMP="$(${pkgs.coreutils}/bin/mktemp --suffix=.exs)"

        ${pkgs.gawk}/bin/awk '
        /^```elixir/ { inblock = 1; next }
        inblock && /^```/ { inblock = 0; next }
        inblock { print }
        ' "$FILE" > "$TMP"

        ${pkgs.elixir}/bin/elixir "$TMP"
      '')
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      ## system utils (linux only)
      pkgs.inotify-tools

      ## pdf documents (linux only)
      wkhtmltopdf
    ];

  home.sessionVariables = {
    PLUG_EDITOR = "vscode://file/__FILE__:__LINE__";
    ELIXIR_EDITOR = "code -g __FILE__:__LINE__";
    ERL_AFLAGS = "-kernel shell_history enabled";
  };

  programs.zsh.envExtra = lib.mkIf config.dotfiles.programs.zsh.enable ''
    export PATH="$HOME/.mix/escripts:$PATH";
  '';

  home.file.".iex.exs" = mkSymlink "iex.exs";
  home.file.".default-mix-commands" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink "default-mix-commands"
  );
}
