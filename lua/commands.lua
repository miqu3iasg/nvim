-- Change the working directory to the current file
vim.api.nvim_create_user_command("Setwd", function()
  vim.cmd.cd(vim.fn.expand("%:p:h"))
end, {})

-- Control autoformatting
vim.api.nvim_create_user_command("FormatDisable", function(_)
  vim.g.disable_autoformat = true
end, {
  desc = "Disable autoformat-on-save",
})

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = "Re-enable autoformat-on-save",
})
