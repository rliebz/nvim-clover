local highlight = require("clover.util").highlight
local get_match_for_line = require("clover.util").get_match_for_line

local function run_coverage(filename, datafile, coverfile, window_id)
	local report_output = vim.fn.system({
		"coverage",
		"json",
		"--data-file",
		datafile,
		"-o",
		coverfile,
	})
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_err_writeln("failed to generate JSON coverage report:")
		vim.api.nvim_err_writeln(report_output)
		return
	end

	local json = vim.fn.json_decode(vim.fn.readfile(coverfile))
	if not json then
		vim.api.nvim_err_writeln("Coverage report not successfully generated")
		return
	end

	local file_report = json["files"][filename]
	if not file_report then
		vim.api.nvim_err_writeln("Coverage not available for file: " .. filename)
		return
	end

	local matches = {}

	for _, line in ipairs(file_report["executed_lines"]) do
		local match = get_match_for_line(line, true)
		table.insert(matches, match)
	end
	for _, line in ipairs(file_report["missing_lines"]) do
		local match = get_match_for_line(line, false)
		table.insert(matches, match)
	end

	highlight(window_id, matches)
end

local function on_exit(exit_code, filename, datafile, window_id)
	if exit_code ~= 0 then
		vim.api.nvim_err_writeln("Failed to get coverage")
		return
	end

	local coverfile = vim.fn.tempname()
	run_coverage(filename, datafile, coverfile, window_id)
	vim.fn.delete(coverfile, "rf")
end

local function up()
	local window_id = vim.fn.win_getid()
	local datafile = vim.fn.tempname()
	local filename = vim.fn.expand("%")
	local package = vim.fn.expand("%:p:h")

	-- coverage.py is incredibly similar, but does not seem to be able to
	-- properly run an annotation report for pytest. But we can probably re-use
	-- some code in the future.
	local cmd = {
		"coverage",
		"run",
		"--data-file",
		datafile,
		"--include",
		filename,
		"-m",
		"pytest",
		package,
	}

	local job_opts = {
		on_exit = function(_, exit_code, _)
			return on_exit(exit_code, filename, datafile, window_id)
		end,
	}

	vim.fn.jobstart(cmd, job_opts)
end

return {
	up = up,
}
