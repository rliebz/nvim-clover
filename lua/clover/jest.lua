local highlight = require("clover.util").highlight
local get_match = require("clover.util").get_match

local function on_exit(exit_code, tempdir, filepath, buf)
	if exit_code ~= 0 then
		vim.notify("Failed to get coverage", vim.log.levels.ERROR)
		return
	end

	local json = vim.fn.json_decode(vim.fn.readfile(tempdir .. "/coverage-final.json"))
	if not json then
		vim.notify("Coverage report not found in tempdir: " .. tempdir, vim.log.levels.ERROR)
		return
	end

	local file_report = json[filepath]
	if not file_report then
		vim.notify("Coverage not available for file: " .. filepath, vim.log.levels.ERROR)
		return
	end

	local statement_counts = file_report.s
	local statement_map = file_report.statementMap

	local matches = {}
	for id, count in pairs(statement_counts) do
		local cov = statement_map[id]
		local pos = {
			start_line = cov.start.line - 1,
			start_col = type(cov.start.column) == "number" and cov.start.column or nil,
			end_line = cov["end"].line - 1,
			end_col = type(cov["end"].column) == "number" and cov["end"].column or nil,
		}

		table.insert(matches, get_match(pos, count > 0))
	end

	highlight(buf, matches)

	vim.fn.delete(tempdir, "rf")
end

local function up()
	local buf = vim.api.nvim_get_current_buf()
	local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
	local filepath = vim.fn.expand("%:p")
	local tempdir = vim.fn.tempname()

	local cmd = {
		"npx",
		"jest",
		"--coverage",
		"--coverageThreshold",
		"{}",
		"--coverage-reporters",
		"json",
		"--collect-coverage-from",
		filename,
		"--coverage-directory",
		tempdir,
	}
	local job_opts = {
		on_exit = function(_, exit_code, _)
			on_exit(exit_code, tempdir, filepath, buf)
		end,
	}

	vim.fn.jobstart(cmd, job_opts)
end

return {
	up = up,
}
