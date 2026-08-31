vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function(args)
    vim.keymap.set("i", ";;", function()
      local line = vim.api.nvim_get_current_line()

      if not line:match(":$") then
        vim.api.nvim_set_current_line(line .. ":")
        vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), #line + 2 })
      end
    end, {
      buffer = args.buf,
      desc = "Insert colon",
    })
  end,
})
