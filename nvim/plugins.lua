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

-- Configure Plugins

local plugins = {
  {
    "projekt0n/github-nvim-theme",
    -- lazy = false,
    -- priority = 1000,
    -- config = function()
    --   require("github-theme").setup({
    --     options = {
    --       transparent = true,
    --       styles = {
    --         comments = "italic",
    --       },
    --     },
    --   })
    --
    --   vim.opt.termguicolors = true
    --   vim.cmd.colorscheme("github_dark")
    -- end,
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        transparent = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      })

      vim.opt.termguicolors = true
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require("lualine").setup({
        options = {
          icons_enabled = true,
          theme = "auto",
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { { 'mode', separator = { left = '' } } },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
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
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup()
    end,
  },
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

    "MeanderingProgrammer/markdown.nvim",
    main = "render-markdown",
    opts = {},
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  },
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
      "3rd/image.nvim",
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
      require("lspconfig").nextls.setup({
        cmd = { HOME .. "/.local/share/nvim/mason/bin/nextls", "--stdio" },
        init_options = {
          extensions = {
            credo = { enable = true },
          },
          experimental = {
            completions = { enable = true },
          },
        },
      })

      vim.keymap.set("n", "K", vim.lsp.buf.hover)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition)
      vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format)
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action)
    end,
  }
}

require("lazy").setup(plugins)
