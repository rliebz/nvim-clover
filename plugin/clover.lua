if vim.g.loaded_clover then
	return
end
vim.g.loaded_clover = true

vim.api.nvim_create_user_command("CloverUp", function()
	require("clover").up()
end, { force = true })

vim.api.nvim_create_user_command("CloverDown", function()
	require("clover").down()
end, { force = true })

vim.api.nvim_create_user_command("CloverToggle", function()
	require("clover").toggle()
end, { force = true })
