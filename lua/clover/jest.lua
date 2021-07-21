local highlight = require("clover").highlight
local line_length = require("clover").line_length
local get_matches = require("clover").get_matches

local function on_exit(exit_code, tempdir)
	if exit_code ~= 0 then
		vim.api.nvim_err_writeln("Failed to get coverage")
		return
	end

	local json = vim.fn.json_decode(vim.fn.readfile(tempdir .. "/coverage-final.json"))

	local filepath = vim.fn.expand("%:p")

	local file_report = json[filepath]
	if not file_report then
		vim.api.nvim_err_writeln("Coverage not available for file: " .. filepath)
		return
	end

	local statement_counts = file_report.s
	local statement_map = file_report.statementMap

	local matches = {}
	for id, count in pairs(statement_counts) do
		local cov = statement_map[id]

		local statement_matches = get_matches(
			cov.start.line,
			-- Start column is zero-based
			type(cov.start.column) == "number" and cov.start.column + 1 or nil,
			cov["end"].line,
			-- End column is also zero based, but non-inclusive
			type(cov["end"].column) == "number" and cov["end"].column or nil,
			count > 0
		)

		for _, match in ipairs(statement_matches) do
			table.insert(matches, match)
		end
	end

	highlight(matches)

	vim.fn.delete(tempdir, "rf")
end

local function jest_up()
	local filename = vim.fn.expand("%")

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
		on_exit = function(job_id, exit_code, event_type)
			on_exit(exit_code, tempdir)
		end,
	}

	local job = vim.fn.jobstart(cmd, job_opts)
end

return {
	jest_up = jest_up,
}
