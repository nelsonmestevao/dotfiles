{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
let
  # On macOS, weasyprint's test_unicode_range fails: its font pixel tests draw
  # a little differently there, and nixpkgs skips some of them but not this
  # one. So the tests are off on macOS only, which keeps the Linux build in the
  # binary cache. A new weasyprint in nixpkgs may fix the test, so it warns.
  testedVersion = "68.1-unstable-2026-05-18";
  weasyprint =
    let
      upstream = pkgs.python313Packages.weasyprint;
    in
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.expiry.expiresWhen (upstream.version != testedVersion)
        "weasyprint ${upstream.version} is in nixpkgs. Build it on the Mac without doCheck = false in home/programs/elixir/elixir.nix. Delete the override if its tests pass, or set testedVersion to the new version if not."
        (upstream.overridePythonAttrs { doCheck = false; })
    else
      upstream;
in
{
  home.packages =
    with pkgs;
    [
      # pdf documents
      pdftk
      weasyprint

      # image processing and optimization
      file
      image_optim
      svgo

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
      # system utils
      inotify-tools

      # pdf documents
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
