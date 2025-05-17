local highlight = require("clover.util").highlight
local get_match_for_line = require("clover.util").get_match_for_line

local function run_coverage(filename, datafile, coverfile, buf)
	local report_output = vim.fn.system({
		"coverage",
		"json",
		"--data-file",
		datafile,
		"-o",
		coverfile,
	})
	if vim.v.shell_error ~= 0 then
		vim.notify("failed to generate JSON coverage report:", vim.log.levels.ERROR)
		vim.notify(report_output, vim.log.levels.ERROR)
		return
	end

	local json = vim.fn.json_decode(vim.fn.readfile(coverfile))
	if not json then
		vim.notify("Coverage report not successfully generated", vim.log.levels.ERROR)
		return
	end

	local file_report = json["files"][filename]
	if not file_report then
		vim.notify("Coverage not available for file: " .. filename, vim.log.levels.ERROR)
		return
	end

	local matches = {}

	for _, line in ipairs(file_report["executed_lines"]) do
		local match = get_match_for_line(buf, line - 1, true)
		table.insert(matches, match)
	end
	for _, line in ipairs(file_report["missing_lines"]) do
		local match = get_match_for_line(buf, line - 1, false)
		table.insert(matches, match)
	end

	highlight(buf, matches)
end

local function on_exit(exit_code, filename, datafile, buf)
	if exit_code ~= 0 then
		vim.notify("Failed to get coverage", vim.log.levels.ERROR)
		return
	end

	local coverfile = vim.fn.tempname()
	run_coverage(filename, datafile, coverfile, buf)
	vim.fn.delete(coverfile, "rf")
end

local function up()
	local buf = vim.api.nvim_get_current_buf()
	local datafile = vim.fn.tempname()
	local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
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
			return on_exit(exit_code, filename, datafile, buf)
		end,
	}

	vim.fn.jobstart(cmd, job_opts)
end

return {
	up = up,
}
