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

-- ## Formatting

-- Format on save is off until you turn it on. A buffer's own setting (the
-- `!` forms) wins over the global one. The BufWritePre autocmd next to the
-- LSP setup in plugins.lua reads these flags.

local function clear_buffer_settings()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.b[buf].autoformat = nil
  end
end

vim.api.nvim_create_user_command("FormatEnable", function(args)
  if args.bang then
    vim.b.autoformat = true
  else
    vim.g.autoformat = true
    clear_buffer_settings()
  end
end, {
  desc = "Format on save (FormatEnable! for this buffer only)",
  bang = true,
})

vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    vim.b.autoformat = false
  else
    vim.g.autoformat = false
    clear_buffer_settings()
  end
end, {
  desc = "Stop formatting on save (FormatDisable! for this buffer only)",
  bang = true,
})

-- ## Conveniences

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "return cursor to where it was last time closing the file",
  pattern = "*",
  command = 'silent! normal! g`"zv',
})

-- ### Git

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  command = "setlocal spell",
})

-- ### Markdown

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "rmd" },
  command = "setlocal spell",
})
