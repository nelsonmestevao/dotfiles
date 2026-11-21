-------------------------------------------------------------------------------
--- # Base Configuration
-------------------------------------------------------------------------------

-- ## File Encodings

-- See https://stackoverflow.com/a/16507826.
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- ## Identation

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

vim.opt.autoindent = true
vim.opt.copyindent = true

vim.opt.expandtab = true

-- ## Whitespace

vim.opt.list = true
vim.opt.listchars = { tab = ">~", trail = "•", nbsp = "•" }

-- ## Spelling

vim.opt.spelllang = "en"

-- ## Split buffers

-- I think the original way of VIM split is not the natural way.
vim.opt.splitbelow = true
vim.opt.splitright = true

-- ## Searching
vim.opt.hlsearch = true

vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- ## Miscellaneous

vim.diagnostic.config({
  virtual_lines = {
    current_line = true,
  },
})

-- One border for every floating window: hover, signature help, the
-- completion docs and diagnostics. Without it they blend into the text.
vim.opt.winborder = "rounded"

vim.opt.autoread = true

vim.opt.cursorline = true

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.colorcolumn = "120"

vim.opt.clipboard = "unnamedplus"

-- ## Completion

-- Open the completion menu as you type. Language servers come first,
-- through 'omnifunc', then up to 5 words each from this buffer, other
-- windows and other buffers.
vim.opt.autocomplete = true
vim.opt.complete = "o,.^5,w^5,b^5"
-- 'autocomplete' ignores `menuone` and `noinsert`; they apply to <C-Space>.
-- Enter takes the first item when none is selected (see plugins.lua).
vim.opt.completeopt = "menuone,noinsert,popup,fuzzy"
