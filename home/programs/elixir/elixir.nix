{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
let
  inherit (import ../../../lib/expiry.nix lib) expiresWhen;

  nixpkgsWeasyprint = pkgs.python313Packages.weasyprint;

  # weasyprint's font-rendering pixel tests render slightly differently on
  # darwin; the nixpkgs derivation already deselects several flaky ones but
  # misses test_unicode_range on this snapshot, so the build fails on macOS.
  # Skip the tests there, leaving the Linux build (and its binary cache) alone.
  # The override can go once nixpkgs deselects that test itself.
  weasyprint =
    if pkgs.stdenv.hostPlatform.isDarwin then
      expiresWhen (lib.elem "test_unicode_range" (nixpkgsWeasyprint.disabledTests or [ ]))
        "nixpkgs skips weasyprint's test_unicode_range itself now. Drop the darwin override in home/programs/elixir/elixir.nix."
        (
          nixpkgsWeasyprint.overridePythonAttrs (_old: {
            doCheck = false;
          })
        )
    else
      nixpkgsWeasyprint;
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
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
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

  # Where `mix escript.install` puts its commands.
  home.sessionPath = [ "$HOME/.mix/escripts" ];

  home.file.".iex.exs" = mkSymlink "iex.exs";
  home.file.".default-mix-commands" = lib.mkIf config.dotfiles.programs.mise.enable (
    mkSymlink "default-mix-commands"
  );
}
