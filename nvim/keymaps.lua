-------------------------------------------------------------------------------
--- # Keymaps
-------------------------------------------------------------------------------

--## Leader Keys

-- The leader keys change the normal behavior of the keys by creating an
-- intermediate mode.

vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- ## Comfortable Escape Key

-- I don't have a Caps lock key because I prefer having a <kdb>Ctrl</kdb> and a
-- <kdb>Esc</kdb> keys there. However, for a quick Escape key I like the `kj`
-- combination since they normally don't appear together in the English
-- dictionary.

-- Because <Esc> is too far away
vim.keymap.set("i", "kj", "<Esc>")
vim.keymap.set("c", "kj", "<Esc>")

-- Leaving insert mode when you are in the terminal mode (inside vim) is just
-- annoying. Using the `Escape` key is much more comfortable.

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

-- ## Embrace the errors

-- We all do this mistakes. I would recommend you to remap your `CapsLock` key
-- system wise. Less errors of this nature would happen. However, if you choose
-- not to, this list of shortcuts will make you a little bit happier.

vim.keymap.set("c", "W!", "w!")
vim.keymap.set("c", "Q!", "q!")
vim.keymap.set("c", "Qall!", "qall!")
vim.keymap.set("c", "Wq", "wq")
vim.keymap.set("c", "Wa", "wa")
vim.keymap.set("c", "wQ", "wq")
vim.keymap.set("c", "WQ", "wq")
vim.keymap.set("c", "W", "w")
vim.keymap.set("c", "Q", "q")
vim.keymap.set("c", "Qall", "qall")

-- ## Old habits are hard to break

-- I could not live without this old habit. Saving with key sequence `Ctrl` + `S`.

vim.keymap.set("n", "<C-s>", ":w<CR>")
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a")
vim.keymap.set("v", "<C-s>", "<Esc>:w<CR>")

-- ## Searching

-- Clean search highlight
vim.keymap.set("n", "<localleader><leader>", ":noh<CR>")

-- These will make it so that going to the next one in a
-- search will center on the line it's found in.
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- ## Easier navigation

-- If you have wrap option enabled (as I do), with a very long sentence, Vim will
-- stretch your current sentence over the multiple rows. But that will still be a
-- single "physical" line. It might be tricky to move between those rows/lines.
--
-- Hitting arrow-down or `j` will move the cursor down one physical line.
--
-- But, hitting `gj` will move the cursor down one displayed line. This will
-- enable you to move around on a long sentence wrapped in multiple rows/lines.

vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- It makes navigating easier. I got this tip from [Mastering Vim Quickly
-- Newsletter](https://masteringvim.com/).

-- ### Fast Buffer Splitting

-- Do you want to split faster?

-- - `h`orizontal
-- - `v`ertical

vim.keymap.set("n", "<leader>h", ":split<CR>")
vim.keymap.set("n", "<leader>v", ":vsplit<CR>")

-- ### Better Pane Switching

vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- ### Better Pane Movement

vim.keymap.set("n", "<C-S-h>", "<C-w>H")
vim.keymap.set("n", "<C-S-j>", "<C-w>J")
vim.keymap.set("n", "<C-S-k>", "<C-w>K")
vim.keymap.set("n", "<C-S-l>", "<C-w>L")

-- ### Cicle between open Buffers

vim.keymap.set("n", "<leader>q", ":bp<CR>")
vim.keymap.set("n", "<leader>w", ":bn<CR>")

-- ### Visual Mode

vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- maintain Visual Mode after shifting > and <

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- ## Coping & Pasting

-- copy entire block to clipboard register
vim.keymap.set("n", "YY", "\"+y<CR>")

