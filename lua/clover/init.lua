-- TODO: You're better than this.
vim.cmd([[
highlight default CloverCovered guifg=Green ctermfg=Green
highlight default CloverUncovered guifg=Red ctermfg=Red
highlight default CloverIgnored guifg=Gray ctermfg=Gray
]])

local toggled = false

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

	toggled = true
end

function M.down()
	vim.fn.clearmatches()
	vim.api.nvim_clear_autocmds({ buffer = 0, group = "clover_cleanup" })
	toggled = false
end

function M.toggle()
	if toggled then
		M.down()
	else
		M.up()
	end
end

return M
