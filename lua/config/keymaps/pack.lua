-- lua/config/keymaps/pack.lua

-- vim.pack updater and prune helpers.

local km = vim.keymap.set

km("n", "<leader>pu", function()
	vim.pack.update()
end, { desc = "Update plugins (vim.pack)" })

-- Remove plugins that are on disk but no longer in vim.pack.add()
km("n", "<leader>pc", function()
	local inactive = vim.iter(vim.pack.get())
		:filter(function(p)
			return not p.active
		end)
		:map(function(p)
			return p.spec.name
		end)
		:totable()

	if #inactive == 0 then
		vim.notify("No inactive plugins")
		return
	end
	vim.pack.del(inactive)
	vim.notify("Removed: " .. table.concat(inactive, ", "))
end, { desc = "Remove inactive plugins" })

km("n", "<leader>pm", "<cmd>Mason<CR>", { desc = "Open Mason" })
