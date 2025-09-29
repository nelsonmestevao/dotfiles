{
  config,
  lib,
  pkgs,
  ...
}:
let
  elixirFilesPath = "nixos/home/programs/elixir";
  erlangFilesPath = "nixos/home/programs/erlang";
 in
{
  imports = [
    ../lib
  ];

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
  ];

  home.file.".iex.exs" = config.lib.dotfiles.mkSymlink "${elixirFilesPath}/iex.exs";
  home.file.".default-mix-commands" = config.lib.dotfiles.mkSymlink "${elixirFilesPath}/default-mix-commands";

  xdg.configFile."rebar/rebar.config" = config.lib.dotfiles.mkSymlink "${erlangFilesPath}/rebar.config";
}
