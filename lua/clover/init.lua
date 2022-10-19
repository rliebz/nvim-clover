--- highlight produces highlights in a document based on matches passed. This
-- will typically be returned from calling get_matches.
--
-- @param window_id the ID of the window to highlight
-- @param matches an array of matches
-- @param matches.group the appropriate highlight group
-- @param matches.pos the positions as documented in matchaddpos
-- @see get_matches
local function highlight(window_id, matches)
	vim.cmd([[
	augroup clover_cleanup
		autocmd! * <buffer>
		autocmd BufWinLeave <buffer> call clover#Down()
	augroup end
	]])

	vim.fn.clearmatches(window_id)
	vim.fn.matchadd("Whitespace", [[\s\+]], 20, -1, { window = window_id })

	for line = 1, vim.fn.line("$", window_id), 1 do
		vim.fn.matchaddpos("CloverIgnored", { line }, 10, -1, { window = window_id })
	end

	for _, match in ipairs(matches) do
		vim.fn.matchaddpos(match.group, match.pos, match.priority, -1, { window = window_id })
	end
end

--- line_length returns the number of display cells a line occupies.
local function line_length(window_id, line_number)
	return vim.fn.strwidth(vim.fn.getbufline(vim.fn.winbufnr(window_id), line_number)[1])
end

-- match_info returns a group and priority suitable for matchaddpos.
--
-- @param covered whether the code is covered by tests
-- @return a table with group and priority
local function match_info(covered)
	local group = "CloverCovered"
	local priority = 10
	if not covered then
		group = "CloverUncovered"
		-- Some reporters such as jest let statements overlap. If that's the case,
		-- consider the uncovered statements to have a higher priority.
		priority = 15
	end

	return {
		group = group,
		priority = priority,
	}
end

-- get_match_for_line returns a single match suitable for matchaddpos.
--
-- @param line_number the line number to highlight
-- @param covered whether the line is covered by tests
-- @return a table with group, pos, and priority
local function get_match_for_line(line_number, covered)
	local info = match_info(covered)
	info.pos = { line_number }
	return info
end

--- get_matches returns a list of matches suitable for matchaddpos. All lines
-- and columns provided must be 1-indexed, and the values must be inclusive.
--
-- @param window_id the id of the window
-- #param pos the position of the highlight
-- @param pos.start_line the first line to highlight
-- @param pos.start_col the optional column of the first line to highlight
-- @param pos.end_line the last line to highlight
-- @param pos.end_col the optional column of the last line to highlight
-- @param covered whether the match is covered by tests
-- @return an array of tables each with a group, pos, and priority
local function get_matches(window_id, pos, covered)
	local info = match_info(covered)

	local function new_match(match_pos)
		return {
			group = info.group,
			priority = info.priority,
			pos = match_pos,
		}
	end

	pos.start_col = pos.start_col or 1
	pos.end_col = pos.end_col or line_length(window_id, pos.end_line)

	if pos.start_line == pos.end_line then
		local match_pos = { {
			pos.start_line,
			pos.start_col,
			pos.end_col - pos.start_col + 1,
		} }
		return { new_match(match_pos) }
	end

	local matches = {}

	local first_length = line_length(window_id, pos.start_line) - pos.start_col + 1
	local first_pos = { { pos.start_line, pos.start_col, first_length } }
	table.insert(matches, new_match(first_pos))

	for line = pos.start_line + 1, pos.end_line - 1, 1 do
		table.insert(matches, new_match({ line }))
	end

	local last_pos = { { pos.end_line, 1, pos.end_col } }
	table.insert(matches, new_match(last_pos))

	return matches
end

return {
	get_matches = get_matches,
	get_match_for_line = get_match_for_line,
	highlight = highlight,
}
