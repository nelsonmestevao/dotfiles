-------------------------------------------------------------------------------
--- # Plugins
------------------------------------------------------------------------------
---

-- Install lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- Configure Plugins

local plugins = {
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({
        options = {
          transparent = true,
          styles = {
            comments = "italic",
          },
        },
      })

      -- Neovim asks the terminal for its background color before it reads
      -- this file, and asks again when the terminal says the OS theme
      -- changed. Pick the color scheme from 'background' each time.
      local function apply_theme()
        local name = vim.o.background == "light" and "github_light" or "github_dark"
        -- Loading a color scheme sets 'background' again. Skip a scheme
        -- that is already loaded, so it doesn't load twice.
        if vim.g.colors_name ~= name then
          vim.cmd.colorscheme(name)
        end
      end

      apply_theme()
      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "background",
        desc = "Match the color scheme to the terminal's theme",
        callback = apply_theme,
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          globalstatus = true,
          icons_enabled = true,
          section_separators = { left = "", right = "" },
          component_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { { "mode", separator = { left = "" } } },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { { "location", separator = { right = "" } } },
        },
      })
    end,
  },
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    config = function()
      require("dashboard").setup()
    end,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },
  -- {
  --   "folke/noice.nvim",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "rcarriga/nvim-notify",
  --   },
  --   config = function()
  --     require("notify").setup({
  --       max_width = 80,
  --     })
  --
  --     require("noice").setup()
  --   end,
  -- },
  {
    "nvim-telescope/telescope.nvim",
    -- v0.2.x uses Neovim's built-in `vim.treesitter` API for preview
    -- highlighting (the old 0.1.8 called the removed `nvim-treesitter.parsers`
    -- master API, which crashes under treesitter's `main` branch). Requires
    -- Neovim 0.11+.
    tag = "v0.2.2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fp", builtin.git_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fm", builtin.marks, {})
      vim.keymap.set("n", "<leader>fr", builtin.lsp_references, {})
      vim.keymap.set("n", "<leader>fs", builtin.spell_suggest, {})
      vim.keymap.set("n", "<leader>fc", builtin.colorscheme, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup({
        defaults = {
          layout_config = {},
          sorting_strategy = "ascending",
        },

        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
  {
    -- The `main` branch is a full rewrite: the old `nvim-treesitter.configs`
    -- module (with `ensure_installed`/`highlight`/`indent`) is gone. Parsers are
    -- installed explicitly and features are enabled per-buffer with the built-in
    -- `vim.treesitter` APIs. See https://github.com/nvim-treesitter/nvim-treesitter.
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- Lazy-load when a file is opened. `BufReadPre`/`BufNewFile` fire *before*
    -- `FileType`, so the highlight autocmd registered in `config` is in place
    -- before the opened buffer's `FileType` fires and reliably catches it.
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      -- nvim-treesitter doesn't list xonsh, so add the grammar here. Pinned to
      -- a commit, since the grammar has no releases.
      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function()
          require("nvim-treesitter.parsers").xonsh = {
            install_info = {
              url = "https://github.com/FoamScience/tree-sitter-xonsh",
              revision = "956a48a6c2a5644ccdb274d918355718b1ea41b5",
              queries = "queries",
            },
          }
        end,
      })

      -- Parsers we always want available. Anything else is installed on demand
      -- the first time a matching buffer is opened (see the autocmd below).
      ts.install({
        "bash",
        "c",
        "css",
        "diff",
        "elixir",
        "gitcommit", -- COMMIT_EDITMSG
        "go",
        "haskell",
        "heex",
        "html",
        "javascript",
        "lua",
        "markdown", -- render-markdown.nvim
        "markdown_inline", -- render-markdown.nvim
        "nix",
        "python",
        "ruby",
        "rust",
        "sql",
        "typescript",
        "tsx", -- .tsx files (filetype typescriptreact) use the `tsx` parser
        "vim",
        "vimdoc",
        "xonsh", -- added above
        "zig",
      })

      -- Open files unfolded; folds are computed from the syntax tree (below).
      vim.o.foldlevelstart = 99

      -- Wire up highlighting, indentation and folding for every buffer whose
      -- language has a parser. Missing-but-available parsers are installed in
      -- the background (this replaces the old `auto_install = true`), so their
      -- highlighting turns on the next time such a file is opened.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim_treesitter", { clear = true }),
        desc = "Enable treesitter highlighting, indentation and folding",
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
          if not lang then
            return
          end

          -- `language.add` loads the parser and reports whether it is available
          -- (without throwing). If it isn't, install it when upstream has one
          -- and bail out; highlighting turns on next time the file is opened.
          local ok, loaded = pcall(vim.treesitter.language.add, lang)
          if not (ok and loaded) then
            if vim.list_contains(ts.get_available(), lang) and not vim.list_contains(ts.get_installed(), lang) then
              ts.install(lang)
            end
            return
          end

          vim.treesitter.start(ev.buf, lang)
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          vim.wo[0][0].foldmethod = "expr"
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end,
      })
    end,
  },
  {
    "tpope/vim-projectionist",
    config = function()
      local prefix = "<leader>a"

      vim.keymap.set("n", prefix .. "a", ":A<CR>")
      vim.keymap.set("n", prefix .. "v", ":AV<CR>")
      vim.keymap.set("n", prefix .. "h", ":AS<CR>")

      vim.g.projectionist_heuristics = {
        ["*"] = {
          ["lib/**/channels/*_channel.ex"] = {
            type = "channel",
            alternate = "test/{dirname}/channels/{basename}_channel_test.exs",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel do",
              "  use {dirname|camelcase|capitalize}, :channel",
              "end",
            },
          },
          ["test/**/channels/*_channel_test.exs"] = {
            alternate = "lib/{dirname}/channels/{basename}_channel.ex",
            type = "test",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ChannelTest do",
              "  use {dirname|camelcase|capitalize}.ChannelCase, async: true",
              "",
              "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel",
              "end",
            },
          },
          ["lib/**/live/*_live.ex"] = {
            type = "liveview",
            alternate = "test/{dirname}/live/{basename}_live_test.exs",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
              "  use {dirname|camelcase|capitalize}, :live_view",
              "end",
            },
          },
          ["test/**/live/*_live_test.exs"] = {
            alternate = "lib/{dirname}/live/{basename}_live.ex",
            type = "test",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
              "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
              "",
              "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live",
              "end",
            },
          },
          ["lib/*.ex"] = {
            alternate = "test/{}_test.exs",
            type = "source",
            template = {
              "defmodule {camelcase|capitalize|dot} do",
              "end",
            },
          },
          ["test/*_test.exs"] = {
            alternate = "lib/{}.ex",
            type = "test",
            template = {
              "defmodule {camelcase|capitalize|dot}Test do",
              "  use ExUnit.Case, async: true",
              "",
              "  alias {camelcase|capitalize|dot}",
              "end",
            },
          },
        },
      }
    end,
  },
  -- Markdown
  {
    -- The community fork: epwalsh/obsidian.nvim is no longer maintained.
    -- It completes notes through its own language server, so it needs no
    -- completion plugin.
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    -- Telescope is the picker. Load it first.
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("obsidian").setup({
        -- Use `:Obsidian quick_switch`, not the old `:ObsidianQuickSwitch`.
        legacy_commands = false,
        picker = { name = "telescope.nvim" },
        workspaces = {
          {
            name = "personal",
            path = "~/Notes",
          },
        },
      })

      vim.opt.conceallevel = 2
    end,
  },
  {

    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    opts = {},
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
  },
  -- {
  --   "3rd/image.nvim",
  --   config = function()
  --     require("image").setup({
  --       -- default options
  --       backed = "kitty",
  --       max_width = 80,
  --       max_height = 60,
  --       integrations = {
  --         markdown = {
  --           resolve_image_path = function(document_path, image_path, fallback)
  --             -- document_path is the path to the file that contains the image
  --             -- image_path is the potentially relative path to the image. for
  --             -- markdown it's `![](this text)`
  --
  --             -- you can call the fallback function to get the default behavior
  --             return fallback(document_path, image_path)
  --           end,
  --         }
  --       }
  --     })
  --   end
  -- },
  -- Databases
  {
    "kndndrj/nvim-dbee",
    cmd = "Dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = function()
      require("dbee").install()
    end,
    config = function()
      require("dbee").setup({
        editor = {
          mappings = {
            { key = "<C-c>", mode = "v", action = "run_selection" },
            { key = "<C-c>", mode = "n", action = "run_file" },
          },
        },
      })
    end,
  },
  -- Navigating
  {
    "romgrk/barbar.nvim",
    version = "^1.0.0",
    -- Draw the tab line right after the first screen, not during startup.
    event = "VeryLazy",
    dependencies = {
      "lewis6991/gitsigns.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("barbar").setup({
        tabpages = false,
        icons = {
          separator_at_end = false,
        },
      })
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      -- "3rd/image.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        window = {
          mappings = {
            ["l"] = "open",
            ["h"] = "close_node",
            ["<leader>o"] = "close_window",
          },
        },
      })
      vim.keymap.set("n", "<leader>o", ":Neotree filesystem reveal right<CR>")
    end,
  },
  {
    "stevearc/oil.nvim",
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      {
        "-",
        "<CMD>Oil<CR>",
        mode = "n",
        desc = "Open parent directory",
      },
    },
    config = function()
      require("oil").setup()
    end,
  },
  -- Terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return vim.o.lines * 0.35
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.45
          end
        end,
        shell = vim.o.shell,
      })
      local prefix = "<leader>s"
      local tescape = "<C-\\><C-n>"

      vim.keymap.set("n", prefix .. "t", ":ToggleTerm<CR>")
      vim.keymap.set("n", prefix .. "a", ":ToggleTermToggleAll<CR>")
      vim.keymap.set("n", prefix .. "v", ":ToggleTerm direction=vertical name=vshell<CR>")
      vim.keymap.set("n", prefix .. "h", ":ToggleTerm direction=horizontal name=hshell<CR>")

      vim.keymap.set("t", prefix .. "t", tescape .. ":ToggleTerm<CR>")

      vim.keymap.set("t", "<C-h>", tescape .. "<C-w>h")
      vim.keymap.set("t", "<C-j>", tescape .. "<C-w>j")
      vim.keymap.set("t", "<C-k>", tescape .. "<C-w>k")
      vim.keymap.set("t", "<C-l>", tescape .. "<C-w>l")

      vim.keymap.set("n", "<C-c><C-c>", ":ToggleTermSendCurrentLine<CR>")
      vim.keymap.set("v", "<C-c><C-c>", ":ToggleTermSendVisualLines<CR>")
    end,
  },
  -- Tests
  {
    "nvim-neotest/neotest",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "jfpedroza/neotest-elixir",
    },
    config = function()
      local neotest = require("neotest")
      neotest.setup({
        adapters = {
          require("neotest-elixir"),
        },
      })

      local prefix = "<leader>t"

      vim.keymap.set("n", prefix .. "t", function()
        neotest.run.run({ vim.fn.expand("%") })
      end)
      vim.keymap.set("n", prefix .. "T", function()
        neotest.run.run(vim.uv.cwd())
      end)
      vim.keymap.set("n", prefix .. "S", function()
        neotest.run.stop()
      end)
      vim.keymap.set("n", prefix .. "r", function()
        neotest.run.run()
      end)
      vim.keymap.set("n", prefix .. "s", function()
        neotest.summary.toggle()
      end)
      vim.keymap.set("n", prefix .. "a", function()
        neotest.run.attach()
      end)
      vim.keymap.set("n", prefix .. "o", function()
        neotest.output.open({ enter = true, auto_close = true })
      end)
      vim.keymap.set("n", prefix .. "p", function()
        neotest.output_panel.toggle()
      end)
      vim.keymap.set("n", prefix .. "w", function()
        neotest.watch.toggle(vim.fn.expand("%"))
      end)
    end,
  },
  -- Git
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        -- Blame the cursor's line at its end, in git-blame.nvim's old format.
        current_line_blame = true,
        current_line_blame_formatter = "<author> • <author_time:%R> • <summary> • <abbrev_sha>",
      })
    end,
  },
  {
    "tpope/vim-fugitive",
    config = function()
      local prefix = "<leader>g"
      vim.keymap.set("n", prefix .. "a", ":Gwrite<CR>")
      vim.keymap.set("n", prefix .. "c", ":Git commit<CR>")
      vim.keymap.set("n", prefix .. "p", ":Git push<CR>")
      vim.keymap.set("n", prefix .. "pf", ":Git push --force-with-lease --force-if-includes<CR>")
      vim.keymap.set("n", prefix .. "l", ":Git pull<CR>")
      vim.keymap.set("n", prefix .. "st", ":Git status<CR>")
      vim.keymap.set("n", prefix .. "b", ":Git blame<CR>")
    end,
  },
  -- Editing
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local autopairs = require("nvim-autopairs")
      -- Enter is mapped below instead. autopairs maps it per buffer, and
      -- that map would win over ours.
      autopairs.setup({ map_cr = false })

      -- Only Ctrl-Y accepts a completion item. 'autocomplete' never selects
      -- an item for you, so it takes the first one when nothing is selected.
      vim.keymap.set("i", "<C-y>", function()
        if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected == -1 then
          return "<C-n><C-y>"
        end
        return "<C-y>"
      end, { expr = true, desc = "Accept the completion item" })

      -- Enter never accepts an item, so it can't pick one while you type.
      -- It closes the menu, keeping what you typed, and starts a new line,
      -- with autopairs' indent between brackets.
      vim.keymap.set("i", "<CR>", function()
        local close_menu = vim.fn.pumvisible() == 1 and vim.keycode("<C-e>") or ""
        return close_menu .. autopairs.autopairs_cr()
      end, { expr = true, replace_keycodes = false, desc = "Close the completion menu and start a new line" })
    end,
  },
  {
    "sitiom/nvim-numbertoggle",
  },
  {
    "RRethy/nvim-treesitter-endwise",
    -- No config needed: endwise auto-attaches via built-in Neovim treesitter APIs.
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
  },
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
    -- Load on the first press. lazy.nvim then replays the key.
    keys = { "<leader>m", "<leader>M" },
    config = function()
      local treesj = require("treesj")

      treesj.setup()

      vim.keymap.set("n", "<leader>m", treesj.toggle)
      vim.keymap.set("n", "<leader>M", function()
        treesj.toggle({ split = { recursive = true } })
      end)
    end,
  },
  -- LSPs
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- nvim 0.11+ API: configure servers with vim.lsp.config and turn them
      -- on with vim.lsp.enable. nvim-lspconfig ships the base configs under
      -- its lsp/ runtime dir; the calls below only layer on our overrides.

      -- ── Servers ─────
      -- Each server, and the commands it needs on PATH. nvim.nix installs the
      -- servers, except hls (the haskell program, to match GHC) and clangd
      -- (clang-tools). A server whose commands are missing stays off, so a
      -- host without that language opens its files with no errors.
      local servers = {
        bashls = { "bash-language-server" },
        clangd = { "clangd" },
        copilot = { "copilot-language-server" },
        expert = { "expert" },
        -- gopls runs `go env` to find the project, and Go comes from mise.
        gopls = { "gopls", "go" },
        hls = { "haskell-language-server-wrapper" },
        lua_ls = { "lua-language-server" },
        nixd = { "nixd" },
        ruff = { "ruff" },
        rust_analyzer = { "rust-analyzer" },
        -- Not ruby-lsp: it downloads its own copy from rubygems on every start.
        solargraph = { "solargraph" },
        sqls = { "sqls" },
        tailwindcss = { "tailwindcss-language-server" },
        ts_ls = { "typescript-language-server" },
        ty = { "ty" },
      }
      local enabled = vim.tbl_filter(function(name)
        return vim.iter(servers[name]):all(function(command)
          return vim.fn.executable(command) == 1
        end)
      end, vim.tbl_keys(servers))
      table.sort(enabled)

      -- ── Completion ─────
      -- 'autocomplete' (options.lua) opens the menu as you type. This lets an
      -- accepted item also run its extra edits, like adding an import or
      -- expanding a snippet.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_completion", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, event.buf)
          end
        end,
      })

      -- Teach lua_ls nvim's Lua API, so it stops calling `vim` an undefined
      -- global. A project with its own .luarc.json keeps its own setup. The
      -- settings change in place: the client reads this same table.
      vim.lsp.config("lua_ls", {
        settings = { Lua = {} },
        before_init = function(_, config)
          local root = config.root_dir
          if root and (vim.uv.fs_stat(root .. "/.luarc.json") or vim.uv.fs_stat(root .. "/.luarc.jsonc")) then
            return
          end
          config.settings.Lua = vim.tbl_deep_extend("force", config.settings.Lua, {
            runtime = { version = "LuaJIT" },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
          })
        end,
      })

      -- Format Nix like bin/format does. In a flake with homes or NixOS
      -- systems, like the dotfiles, also complete and describe their options
      -- (dotfiles.programs.zsh.showHost), read from the first of each.
      -- Elsewhere the expressions fail and nixd goes without.
      local first = function(configurations)
        return "(builtins.head (builtins.attrValues (builtins.getFlake (toString ./.))."
          .. configurations
          .. ")).options"
      end
      vim.lsp.config("nixd", {
        settings = {
          nixd = {
            formatting = { command = { "nixfmt" } },
            options = {
              ["home-manager"] = { expr = first("homeConfigurations") },
              nixos = { expr = first("nixosConfigurations") },
            },
          },
        },
      })

      -- sqls formats and completes SQL without a database, but says "no
      -- database connection" each time it opens a file. Hide that message.
      vim.lsp.config("sqls", {
        handlers = {
          ["window/showMessage"] = function(err, result, ctx)
            if result and result.message:find("no database connection", 1, true) then
              return
            end
            return vim.lsp.handlers["window/showMessage"](err, result, ctx)
          end,
        },
      })

      -- Keep Copilot away from Haskell and C files, as Supermaven was: never
      -- send them to the server. Neovim opens `.h` headers as C++, so skip
      -- them by name. Everywhere else, use the git root like nvim-lspconfig
      -- does.
      vim.lsp.config("copilot", {
        root_dir = function(bufnr, on_dir)
          local private = { "haskell", "lhaskell", "cabal", "c" }
          if vim.list_contains(private, vim.bo[bufnr].filetype) or vim.api.nvim_buf_get_name(bufnr):match("%.h$") then
            return
          end
          on_dir(vim.fs.root(bufnr, ".git"))
        end,
      })

      -- Expert: the official Elixir language server (successor to lexical /
      -- next-ls / elixir-ls). filetypes/root_dir are spelled out here so this
      -- works even before nvim-lspconfig ships the expert base config.
      vim.lsp.config("expert", {
        cmd = { "expert", "--stdio" },
        filetypes = { "elixir", "eelixir", "heex", "surface" },
        root_dir = function(bufnr, on_dir)
          -- Elixir workspaces may have multiple mix.exs files (umbrella apps).
          -- Search upward for up to two and treat the higher one as the root.
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local matches = vim.fs.find({ "mix.exs" }, { upward = true, limit = 2, path = fname })
          local child_or_root_path, maybe_umbrella_path = unpack(matches)
          on_dir(vim.fs.dirname(maybe_umbrella_path or child_or_root_path))
        end,
      })

      -- HLS keeps semantic tokens off unless asked. nvim requests them anyway,
      -- so turn them on: better highlighting, and no error in lsp.log for
      -- every Haskell file. HLS formats with ormolu unless a fourmolu.yaml
      -- sits at or above the project root; fourmolu reads that file, ormolu
      -- ignores it. The settings change in place: the client reads this table.
      -- HLS also checks and formats .cabal files, with cabal-gild from the
      -- haskell program.
      vim.lsp.config("hls", {
        filetypes = { "haskell", "lhaskell", "cabal" },
        settings = {
          haskell = {
            cabalFormattingProvider = "cabal-gild",
            plugin = { semanticTokens = { globalOn = true } },
          },
        },
        before_init = function(_, config)
          local found = vim.fs.find("fourmolu.yaml", { upward = true, path = config.root_dir })
          if #found > 0 then
            config.settings.haskell.formattingProvider = "fourmolu"
          end
        end,
      })

      vim.lsp.config("tailwindcss", {
        init_options = {
          userLanguages = {
            elixir = "html-eex",
            eelixir = "html-eex",
            heex = "html-eex",
          },
        },
      })

      vim.lsp.enable(enabled)
      -- Show Copilot's suggestions as ghost text.
      vim.lsp.inline_completion.enable()

      -- ── Formatting ─────
      -- nvim starts a buffer's servers when it sets the file type. Note the
      -- time, so format() knows how long a missing server may still take.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("lsp_started_at", { clear = true }),
        callback = function(event)
          vim.b[event.buf].lsp_started_at = vim.uv.now()
        end,
      })

      -- Formats the buffer. A server that is still starting can't format yet
      -- (HLS takes a few seconds: it asks cabal for the GHC version first), so
      -- wait for it instead of failing with "no matching language servers".
      -- A server that hasn't attached 15 seconds after the file opened isn't
      -- coming (tailwindcss outside a Tailwind project, say): don't wait.
      local function format()
        local bufnr = vim.api.nvim_get_current_buf()
        local function ready()
          return #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" }) > 0
        end

        if not ready() then
          local filetype = vim.bo[bufnr].filetype
          local attached = vim.tbl_map(function(client)
            return client.name
          end, vim.lsp.get_clients({ bufnr = bufnr }))
          local starting = vim.tbl_filter(function(name)
            local filetypes = vim.lsp.config[name].filetypes
            return filetypes ~= nil and vim.list_contains(filetypes, filetype) and not vim.list_contains(attached, name)
          end, enabled)

          local wait = 15000 - (vim.uv.now() - (vim.b[bufnr].lsp_started_at or 0))
          if #starting == 0 or wait <= 0 then
            vim.notify("No language server formats this file.", vim.log.levels.WARN)
            return
          end

          vim.notify("Waiting for " .. table.concat(starting, ", ") .. " to start…")
          if not vim.wait(wait, ready, 100) then
            vim.notify(
              "No language server formats this file: "
                .. table.concat(starting, ", ")
                .. " didn't attach. See :checkhealth vim.lsp.",
              vim.log.levels.WARN
            )
            return
          end
        end

        -- Async: a sync format gives up after 1 second, and a server that is
        -- still indexing (rust-analyzer, HLS) can take longer than that.
        vim.lsp.buf.format({ bufnr = bufnr, async = true })
      end

      -- Format on save, once :FormatEnable turns it on (see commands.lua).
      -- Saving never waits for a server that is still starting: with none
      -- ready, the file saves as it is.
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = true }),
        callback = function(event)
          local on = vim.b[event.buf].autoformat
          if on == nil then
            on = vim.g.autoformat
          end
          if on and #vim.lsp.get_clients({ bufnr = event.buf, method = "textDocument/formatting" }) > 0 then
            vim.lsp.buf.format({ bufnr = event.buf, timeout_ms = 3000 })
          end
        end,
      })

      -- ── Keymaps ─────
      -- `K` needs no map: nvim maps it to hover in a buffer whose server can
      -- hover, and leaves it alone elsewhere, like in a help file.
      --
      -- `gd` goes to the definition only where a server can find one. Copilot
      -- attaches almost everywhere and can't, so without the check `gd` would
      -- lose vim's own jump in every file.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method("textDocument/definition") then
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = event.buf })
          end
        end,
      })
      -- Open the documentation in a vertical split
      vim.keymap.set("n", "<leader>K", function()
        local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/hover" })
        if #clients == 0 then
          return
        end

        local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding)
        vim.lsp.buf_request(0, "textDocument/hover", params, function(err, result)
          if err or not result or not result.contents then
            return
          end

          local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
          if vim.tbl_isempty(lines) then
            return
          end

          vim.cmd("vnew")
          local buf = vim.api.nvim_get_current_buf()
          vim.bo[buf].buftype = "nofile"
          vim.bo[buf].bufhidden = "wipe"
          vim.bo[buf].swapfile = false
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].filetype = "markdown"
        end)
      end, { noremap = true, silent = true })
      vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, { desc = "Ask the language server for completions" })
      -- <C-y> takes Copilot's suggestion first, as it did with Supermaven.
      -- With none showing, it's the built-in <C-y>, which accepts the menu
      -- item. Neovim can't accept one word of a suggestion, so <C-j> moves
      -- to the next suggestion instead.
      vim.keymap.set("i", "<C-y>", function()
        if vim.lsp.inline_completion.get() then
          -- Close the menu too, or its next key would undo the suggestion.
          return vim.fn.pumvisible() == 1 and "<C-e>" or ""
        end
        return "<C-y>"
      end, { expr = true, desc = "Accept the Copilot suggestion or the menu item" })
      vim.keymap.set("i", "<C-j>", function()
        vim.lsp.inline_completion.select()
      end, { desc = "Show the next Copilot suggestion" })
      vim.keymap.set("n", "<leader>gf", format, { desc = "Format the file with its language server" })
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action)
    end,
  },
}

require("lazy").setup(plugins)
