-------------------------------------------------------------------------------
--- # Base Configuration
-------------------------------------------------------------------------------

-- ## File Encodings

-- See https://stackoverflow.com/a/16507826.
-- The encoding displayed.
vim.opt.encoding = "utf-8"
-- The encoding written to file.
vim.opt.fileencoding = "utf-8"

-- ## Identation

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

vim.opt.autoindent = true -- always set autoindenting on
vim.opt.copyindent = true -- copy the previous indentation on autoindenting

-- On visual mode indent with spaces.
vim.opt.expandtab = true

-- ## Whitespace

vim.opt.list = true
vim.opt.listchars = { tab = '>~', trail = '•',  nbsp = '•'}

-- ## Spelling

-- This will make the default spell language to English.
vim.opt.spelllang = "en"

-- ## Split buffers

-- I think the original way of VIM split is not the natural way.
vim.opt.splitbelow = true
vim.opt.splitright = true

-- ## Searching
vim.opt.hlsearch = true -- highlights the term you search for

vim.opt.incsearch= true
vim.opt.ignorecase = true
vim.opt.smartcase = true -- when searching try to be smart about cases

-- ## Miscellaneous

-- When a file has been detected to have been changed from the outside, automatically read it again.
vim.opt.autoread = true

-- highlight cursor line underneath the cursor horizontally
vim.opt.cursorline = true

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.colorcolumn = "120"

vim.opt.clipboard = "unnamedplus"
