vim.api.nvim_set_hl(0, "CloverCovered", { fg = "Green", default = true })
vim.api.nvim_set_hl(0, "CloverUncovered", { fg = "Red", default = true })
vim.api.nvim_set_hl(0, "CloverIgnored", { fg = "Gray", default = true })

local toggled = {}

local M = {}

local function contains(arr, el)
	for _, v in ipairs(arr) do
		if v == el then
			return true
		end
	end

	return false
end

function M.up()
	-- TODO: Test runners are not safe assumptions based on language
	if vim.o.filetype == "go" then
		require("clover.go").up()
	elseif vim.o.filetype == "python" then
		require("clover.pytest").up()
	elseif contains({
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	}, vim.o.filetype) then
		require("clover.jest").up()
	else
		vim.notify("Unsupported file type: " .. vim.o.filetype, vim.log.ERROR)
	end

	toggled[vim.api.nvim_get_current_buf()] = true
end

function M.down()
	local buf = vim.api.nvim_get_current_buf()

	vim.api.nvim_buf_clear_namespace(buf, require("clover.util").ns_id, 0, -1)
	vim.api.nvim_clear_autocmds({
		buffer = 0,
		group = require("clover.cleanup").augroup,
	})
	toggled[buf] = false
end

function M.toggle()
	if toggled[vim.api.nvim_get_current_buf()] then
		M.down()
	else
		M.up()
	end
end

return M
