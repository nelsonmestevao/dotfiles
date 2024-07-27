-------------------------------------------------------------------------------
--- # Commands
-------------------------------------------------------------------------------

-- ## Writing mode

-- Change the spell between English and Portuguese more easily.

local function changespell(lang)
  vim.opt.spell = true
  vim.opt.spelllang = lang
end

vim.api.nvim_create_user_command("PT", function()
  changespell("pt")
end, {})

vim.api.nvim_create_user_command("EN", function()
  changespell("en")
end, {})

-- ## Conveniences

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "return cursor to where it was last time closing the file",
  pattern = "*",
  command = 'silent! normal! g`"zv',
})

-- ### Git

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  command = 'setlocal spell',
})

-- ### Markdown

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*.md,*.rmd",
  command = 'setlocal spell',
})

-- ## Darkmode and lightmode

-- function! Dark()
--   set background=dark
--   silent !mode dark
-- endfunction
--
-- function! Light()
--   set background=light
--   silent !mode light
-- endfunction
--
-- command! Dark call Dark()
-- command! Light call Light()
