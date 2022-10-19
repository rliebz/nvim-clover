local highlight = require("clover").highlight
local get_match_for_line = require("clover").get_match_for_line

local function on_exit(exit_code, dirname, filename, window_id)
	if exit_code ~= 0 then
		vim.api.nvim_err_writeln("Failed to get coverage")
		return
	end

	local coverfile = dirname .. "/" .. filename:gsub("/", "_") .. ",cover"

	if not vim.fn.filereadable(coverfile) then
		vim.api.nvim_err_writeln("Failed to read coverfile: " .. coverfile)
		return
	end

	local matches = {}

	local lines = vim.fn.readfile(coverfile)
	for i, line in ipairs(lines) do
		local key = line:sub(1, 1)

		if key == ">" then
			local match = get_match_for_line(i, true)
			table.insert(matches, match)
		elseif key == "!" then
			local match = get_match_for_line(i, false)
			table.insert(matches, match)
		end
	end

	highlight(window_id, matches)

	vim.fn.delete(dirname, "rf")
end

local function up()
	local window_id = vim.fn.win_getid()
	local package = vim.fn.expand("%:h") -- TODO: This is brittle/janky
	local tempdir = vim.fn.tempname()
	local filename = vim.fn.expand("%") -- TODO: This is brittle/janky

	-- coverage.py is incredibly similar, but does not seem to be able to
	-- properly run an annotation report for pytest. But we can probably re-use
	-- some code in the future.
	local cmd = {
		"pytest",
		"--cov-report",
		"annotate:" .. tempdir,
		"--cov",
		package,
	}

	local job_opts = {
		on_exit = function(_, exit_code, _)
			return on_exit(exit_code, tempdir, filename, window_id)
		end,
	}

	vim.fn.jobstart(cmd, job_opts)
end

return {
	up = up,
}
