{
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    neovim
    # nvim-treesitter `main` branch compiles parsers locally at runtime, which
    # needs the tree-sitter CLI plus a C compiler on PATH. (macOS uses the
    # Xcode Command Line Tools' clang instead of this gcc.)
    tree-sitter
    gcc

    # ── Language servers ─────
    # plugins.lua turns a server on only when its command is on PATH, so
    # every server comes from here, not from Mason: Mason's binaries often
    # don't run on NixOS. HLS is the one exception. It must match GHC, so the
    # haskell program installs it.
    bash-language-server
    shellcheck # bash-language-server shows its warnings
    shfmt # bash-language-server formats with it
    beamPackages.expert
    # Copilot's suggestions as ghost text, through Neovim's built-in inline
    # completion. It's unfree, which config/overlays.nix allows.
    copilot-language-server
    gopls
    lua-language-server
    nixd
    nixfmt # nixd formats with it, like bin/format
    ruff
    solargraph
    sqls
    tailwindcss-language-server
    # Python types. Not basedpyright: it pulls in 423 MiB of npm packages.
    ty
    typescript-language-server
    typescript # typescript-language-server needs tsserver too
    # rustup puts a rust-analyzer of its own on PATH, which fails until you
    # add the component by hand. This one wins.
    (lib.hiPrio rust-analyzer)
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
  };

  home.shellAliases = {
    v = "nvim -p";
    vi = "nvim";
    vim = "nvim";
  };

  xdg.configFile."nvim/init.lua" = mkSymlink ./init.lua;
}
