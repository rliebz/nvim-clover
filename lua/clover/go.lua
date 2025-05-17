local highlight = require("clover.util").highlight
local get_match = require("clover.util").get_match

local function parse_line(line)
	local pat = [[\([^:]\+\):\(\d\+\)\.\(\d\+\),\(\d\+\)\.\(\d\+\)\s\(\d\+\)\s\(\d\+\)]]
	local tokens = vim.fn.matchlist(line, pat)

	return {
		file = tokens[2],
		start_line = vim.fn.str2nr(tokens[3]),
		start_col = vim.fn.str2nr(tokens[4]),
		end_line = vim.fn.str2nr(tokens[5]),
		end_col = vim.fn.str2nr(tokens[6]),
		number_of_statements = vim.fn.str2nr(tokens[7]),
		count = vim.fn.str2nr(tokens[8]),
	}
end

local function on_exit(exit_code, filename, coverfile, buf)
	if exit_code ~= 0 then
		vim.notify("Failed to get coverage", vim.log.levels.ERROR)
		return
	end

	if not vim.fn.filereadable(coverfile) then
		vim.notify("Failed to read coverfile: " .. coverfile, vim.log.levels.ERROR)
		return
	end

	local matches = {}

	local lines = vim.fn.readfile(coverfile)
	for _, line in ipairs({ unpack(lines, 2) }) do
		local cov = parse_line(line)

		if filename == vim.fn.fnamemodify(cov.file, ":t") then
			local pos = {
				start_line = cov.start_line - 1,
				start_col = cov.start_col - 1,
				end_line = cov.end_line - 1,
				end_col = cov.end_col - 1,
			}

			table.insert(matches, get_match(pos, cov.count > 0))
		end
	end

	highlight(buf, matches)

	vim.fn.delete(coverfile)
end

local function up()
	local filename = vim.fn.expand("%:t")
	local buf = vim.api.nvim_get_current_buf()
	local tempname = vim.fn.tempname()

	local job_opts = {
		cwd = vim.fn.expand("%:h"),
		on_exit = function(_, exit_code, _)
			return on_exit(exit_code, filename, tempname, buf)
		end,
	}

	local cmd_args = { "-coverprofile", tempname }
	if vim.g.loaded_test then
		cmd_args = vim.fn["test#base#options"]("go#gotest", cmd_args)
		cmd_args = vim.fn["test#base#options"]("go#gotest", cmd_args, "suite")
	end

	local cmd = { "go", "test" }
	for _, arg in ipairs(cmd_args) do
		table.insert(cmd, arg)
	end

	vim.fn.jobstart(cmd, job_opts)
end

return {
	up = up,
}
