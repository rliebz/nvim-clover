local highlight = require("clover.util").highlight
local get_matches = require("clover.util").get_matches

local function on_exit(exit_code, tempdir, filepath, window_id)
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
			start_line = cov.start.line,
			-- Start column is zero-based
			start_col = type(cov.start.column) == "number" and cov.start.column + 1 or nil,
			end_line = cov["end"].line,
			-- End column is also zero based, but non-inclusive
			end_col = type(cov["end"].column) == "number" and cov["end"].column or nil,
		}

		local statement_matches = get_matches(window_id, pos, count > 0)

		for _, match in ipairs(statement_matches) do
			table.insert(matches, match)
		end
	end

	highlight(window_id, matches)

	vim.fn.delete(tempdir, "rf")
end

local function up()
	local window_id = vim.fn.win_getid()
	local filename = vim.fn.expand("%")
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
			on_exit(exit_code, tempdir, filepath, window_id)
		end,
	}

	vim.fn.jobstart(cmd, job_opts)
end

return {
	up = up,
}
