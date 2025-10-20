{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    # elixir_1_18
    # erlang_27

    ## system utils
    inotify-tools

    ## pdf documents
    k2pdfopt
    wkhtmltopdf

    ## image processing and optimization
    file
    image_optim
    # gifsicle
    # jpegoptim
    # libwebp
    nodePackages.svgo
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
  ];

  home.file.".iex.exs" = mkSymlink "iex.exs";
  home.file.".default-mix-commands" = mkSymlink "default-mix-commands";
}
