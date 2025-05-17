local M = {}

M.ns_id = vim.api.nvim_create_namespace("nvim_clover")

--- @class (exact) Match
--- @field group string         Highlight group name
--- @field priority integer     Extmark priority
--- @field pos MatchPos         The position range to highlight

--- @class (exact) MatchPos
--- @field start_line integer   0-based start line
--- @field start_col integer    0-based start column
--- @field end_line integer     0-based end line
--- @field end_col integer      0-based end column

--- @class (exact) MatchInfo
--- @field group string         Highlight group name
--- @field priority integer     Extmark priority

--- @param buf integer
--- @param line_number integer
local function line_length(buf, line_number)
	local last_line_text = vim.api.nvim_buf_get_lines(buf, line_number, line_number + 1, false)[1] or ""
	return #last_line_text
end

--- highlight produces highlights in a document based on matches passed.
---
--- @param buf integer      The ID of the buffer to highlight
--- @param matches Match[]  An array of matches
function M.highlight(buf, matches)
	vim.api.nvim_create_autocmd("BufWinLeave", {
		buffer = 0,
		group = require("clover.cleanup").augroup,
		callback = function()
			require("clover").down()
		end,
	})

	vim.api.nvim_buf_clear_namespace(buf, M.ns_id, 0, -1)

	local last_line = vim.api.nvim_buf_line_count(buf) - 1
	local last_col = line_length(buf, last_line)
	vim.api.nvim_buf_set_extmark(buf, M.ns_id, 0, 0, {
		end_row = last_line,
		end_col = last_col,
		hl_group = "CloverIgnored",
		priority = 1000,
	})

	for _, match in ipairs(matches) do
		local pos = match.pos
		vim.api.nvim_buf_set_extmark(buf, M.ns_id, pos.start_line, pos.start_col, {
			end_row = pos.end_line,
			end_col = pos.end_col,
			hl_group = match.group,
			priority = match.priority,
		})
	end
end

--- @param covered boolean        Whether the code is covered by tests
--- @return MatchInfo
local function match_info(covered)
	local group = "CloverCovered"
	local priority = 1500
	if not covered then
		group = "CloverUncovered"
		-- Some reporters such as jest let statements overlap. If that's the case,
		-- consider the uncovered statements to have a higher priority.
		priority = 2000
	end

	return {
		group = group,
		priority = priority,
	}
end

--- @param buf integer          The ID of the buffer
--- @param line_number integer  The line number to highlight
--- @param covered boolean      Whether the line is covered by tests
--- @return Match
function M.get_match_for_line(buf, line_number, covered)
	local info = match_info(covered)

	return {
		group = info.group,
		priority = info.priority,
		pos = {
			start_line = line_number,
			end_line = line_number,
			start_col = 0,
			end_col = line_length(buf, line_number),
		},
	}
end

--- @param pos MatchPos     The position of the highlight
--- @param covered boolean  Whether the line is covered by tests
--- @return Match
function M.get_match(pos, covered)
	local info = match_info(covered)

	return {
		group = info.group,
		priority = info.priority,
		pos = pos,
	}
end

return M
