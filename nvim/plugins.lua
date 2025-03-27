-------------------------------------------------------------------------------
--- # Plugins
------------------------------------------------------------------------------
---

HOME = os.getenv("HOME")

-- Install lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- Utilities

-- Function to get the current GNOME theme mode
local function get_gnome_theme_mode()
  local command = "gsettings get org.gnome.desktop.interface color-scheme"
  local ok, result = pcall(vim.fn.system, command)

  if not ok then
    return nil, "Failed to execute command to get GNOME theme."
  end

  result = string.lower(result:gsub("%s+", ""))

  if result == "'prefer-dark'" then
    return "dark"
  elseif result == "'default'" then
    return "light"
  else
    return nil, "Unexpected theme value from GNOME settings."
  end
end

-- Configure Plugins

local plugins = {
  {
    "projekt0n/github-nvim-theme",
    dependencies = { "vimpostor/vim-lumen" },
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

      local current_os_theme = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme")
      if string.match(current_os_theme, "dark") or string.match(current_os_theme, "Dark") then
        vim.cmd.colorscheme("github_dark")
      else
        vim.cmd.colorscheme("github_light")
      end

      local mode, err = get_gnome_theme_mode()
      if mode then
        vim.cmd.colorscheme(mode == "dark" and "github_dark" or "github_light")
      else
        print("Error detecting theme: " .. err)
        vim.cmd.colorscheme("github_dark")
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "LumenLight",
        callback = function()
          vim.cmd.colorscheme("github_light")
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "LumenDark",
        callback = function()
          vim.cmd.colorscheme("github_dark")
        end,
      })
    end,
  },
  {
    "folke/tokyonight.nvim",
    -- lazy = false,
    -- priority = 1000,
    -- config = function()
    --   require("tokyonight").setup({
    --     transparent = true,
    --     styles = {
    --       sidebars = "transparent",
    --       floats = "transparent",
    --     },
    --   })
    --
    --   vim.opt.termguicolors = true
    --   vim.cmd.colorscheme("tokyonight")
    -- end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          globalstatus = true,
          icons_enabled = true,
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { { 'mode', separator = { left = '' } } },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { { 'location', separator = { right = '' } } },
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
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fp", builtin.git_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fm", builtin.marks, {})
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
          layout_config = {
          },
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
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        auto_install = true,
        ensure_installed = {
          "bash",
          "c",
          "haskell",
          "lua",
          "python",
          "ruby",
          "go",
          "rust",
          "zig",
          "vim",
          "vimdoc",
          "sql",
          "elixir",
          "heex",
          "javascript",
          "typescript",
          "html",
          "css",
        },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
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
              "end"
            }
          },
          ["test/**/channels/*_channel_test.exs"] = {
            alternate = "lib/{dirname}/channels/{basename}_channel.ex",
            type = "test",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ChannelTest do",
              "  use {dirname|camelcase|capitalize}.ChannelCase, async: true",
              "",
              "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel",
              "end"
            }
          },
          ["lib/**/live/*_live.ex"] = {
            type = "liveview",
            alternate = "test/{dirname}/live/{basename}_live_test.exs",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
              "  use {dirname|camelcase|capitalize}, :live_view",
              "end"
            }
          },
          ["test/**/live/*_live_test.exs"] = {
            alternate = "lib/{dirname}/live/{basename}_live.ex",
            type = "test",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
              "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
              "",
              "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live",
              "end"
            }
          },
          ["lib/*.ex"] = {
            alternate = "test/{}_test.exs",
            type = "source",
            template = {
              "defmodule {camelcase|capitalize|dot} do",
              "end"
            }
          },
          ["test/*_test.exs"] = {
            alternate = "lib/{}.ex",
            type = "test",
            template = {
              "defmodule {camelcase|capitalize|dot}Test do",
              "  use ExUnit.Case, async: true",
              "",
              "  alias {camelcase|capitalize|dot}",
              "end"
            }
          }
        }
      }
    end
  },
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        ignore_filetypes = { haskell = true, c = true },
        keymaps = {
          accept_suggestion = "<C-y>",
          accept_word = "<C-j>",
        }
      })
    end
  },
  -- Markdown
  {
    "epwalsh/obsidian.nvim",
    version      = "*",
    lazy         = true,
    ft           = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim"
    },
    config       = function()
      require("obsidian").setup({
        workspaces = {
          {
            name = "personal",
            path = "~/Code/Personal/notes",
          },
        },
      })

      vim.opt.conceallevel = 2
    end
  },
  {

    "MeanderingProgrammer/render-markdown.nvim",
    opts = {},
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
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
          }
        }
      })
    end,
  },
  -- Navigating
  {
    'romgrk/barbar.nvim',
    version = '^1.0.0',
    dependencies = {
      'lewis6991/gitsigns.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require("barbar").setup({
        tabpages = false,
        icons = {
          separator_at_end = false,
        },
      })
    end
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
    'akinsho/toggleterm.nvim',
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
        shell = vim.o.shell
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
    end
  },
  -- Git
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
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
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    config = function()
      vim.g.gitblame_message_template = '<author> • <date> • <summary> • <sha>'
      vim.g.gitblame_date_format = "%r"
      vim.g.gitblame_highlight_group = "Comment"
      vim.g.gitblame_set_extmark_options = {
        hl_mode = "combine",
      }
    end
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
      require("nvim-autopairs").setup()
    end,
  },
  {
    "RRethy/nvim-treesitter-endwise",
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
    config = function()
      require("nvim-treesitter.configs").setup({
        endwise = {
          enable = true,
        },
      })
    end,
  },
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
    config = function()
      local treesj = require("treesj")

      treesj.setup()

      vim.keymap.set("n", "<leader>m", treesj.toggle)
      vim.keymap.set("n", "<leader>M", function()
        treesj.toggle({ split = { recursive = true } })
      end)
    end,
  },
  {
    "editorconfig/editorconfig-vim",
  },
  -- LSPs
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls" },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("lspconfig").lua_ls.setup({})
      -- require("lspconfig").nextls.setup({
      --   cmd = { HOME .. "/.local/share/nvim/mason/bin/nextls", "--stdio" },
      --   init_options = {
      --     extensions = {
      --       credo = { enable = true },
      --     },
      --     experimental = {
      --       completions = { enable = true },
      --     },
      --   },
      -- })
      require("lspconfig").bashls.setup({
        cmd = { HOME .. "/.local/share/nvim/mason/bin/bash-language-server", "start" },
      })

      require("lspconfig").sqlls.setup({
        cmd = { HOME .. "/.local/share/nvim/mason/bin/sql-language-server", "up", "--method", "stdio" },
      })

      require("lspconfig").lexical.setup({
        cmd = { HOME .. "/.local/share/nvim/mason/bin/lexical", "--stdio" },
      })

      require("lspconfig").hls.setup({
        cmd = { HOME .. "/.local/share/nvim/mason/bin/haskell-language-server-wrapper", "--lsp" },
      })

      vim.keymap.set("n", "K", vim.lsp.buf.hover)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition)
      vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format)
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action)
    end,
  }
}

require("lazy").setup(plugins)
