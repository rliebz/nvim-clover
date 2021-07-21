local highlight = require("clover").highlight

local function length(line_number)
	return vim.fn.strwidth(vim.fn.getline(line_number))
end

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
		local group = "CloverUncovered"
		if count > 0 then
			group = "CloverCovered"
		end

		local cov = statement_map[id]

		local first_length = length(cov.start.line) - cov.start.column + 1
		local first_pos = { { cov.start.line, cov.start.column, first_length } }
		table.insert(matches, { group = group, pos = first_pos })

		for line = cov.start.line + 1, cov["end"].line - 1, 1 do
			table.insert(matches, { group = group, pos = { line } })
		end

		local last_pos = { { cov["end"].line, 1, cov["end"].column or length(cov["end"].line) } }
		table.insert(matches, { group = group, pos = last_pos })
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
