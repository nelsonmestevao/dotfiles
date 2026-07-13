{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    neovim
    # Elixir language server (used by nvim LSP as `expert`). Installed via nix
    # rather than mason because mason ships burrito-packed binaries that don't
    # run on NixOS.
    beamPackages.expert
    # nvim-treesitter `main` branch compiles parsers locally at runtime, which
    # needs the tree-sitter CLI plus a C compiler on PATH. (macOS uses the
    # Xcode Command Line Tools' clang instead of this gcc.)
    tree-sitter
    gcc
    # Tailwind CSS language server, enabled in plugins.lua via `vim.lsp.enable`.
    # Its config uses the default `tailwindcss-language-server` cmd, so the
    # binary just needs to be on PATH.
    tailwindcss-language-server
    # TypeScript/TSX language server (`ts_ls`), enabled in plugins.lua. Needs
    # both the server and `typescript` (tsserver) on PATH.
    typescript-language-server
    typescript
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
  };

  xdg.configFile."nvim/init.lua" = mkSymlink "init.lua";
}
