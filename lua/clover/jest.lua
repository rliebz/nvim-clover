local highlight = require("clover").highlight
local line_length = require("clover").line_length
local get_matches = require("clover").get_matches

local function on_exit(exit_code, tempdir)
	if exit_code ~= 0 then
		vim.api.nvim_err_writeln("failed to get coverage")
		return
	end

	local json = vim.fn.json_decode(vim.fn.readfile(tempdir .. "/coverage-final.json"))

	local filepath = vim.fn.expand("%:p")

	local statement_counts = json[filepath].s
	local statement_map = json[filepath].statementMap

	local matches = {}
	for id, count in pairs(statement_counts) do
		local cov = statement_map[id]

		local statement_matches = get_matches(
			cov.start.line,
			cov.start.column + 1,
			cov["end"].line,
			cov["end"].column + 1,
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
