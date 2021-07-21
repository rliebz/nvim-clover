--- line_length returns the number of display cells a line occupies.
local function line_length(line_number)
	return vim.fn.strwidth(vim.fn.getline(line_number))
end

--- highlight produces highlights in a document based on matches passed. This
-- will typically be returned from calling get_matches.
--
-- @param matches an array of matches
-- @param matches.group the appropriate highlight group
-- @param matches.pos the positions as documented in matchaddpos
-- @see get_matches
local function highlight(matches)
	vim.cmd([[
	augroup clover_cleanup
		autocmd! * <buffer>
		autocmd BufLeave <buffer> ++once call clover#Down()
	augroup end
	]])

	vim.fn.clearmatches()
	vim.fn.matchadd("Whitespace", [[\s\+]], 20)

	for line = 1, vim.fn.line("$"), 1 do
		vim.fn.matchaddpos("CloverIgnored", { line })
	end

	for _, match in ipairs(matches) do
		vim.fn.matchaddpos(match.group, match.pos, match.priority)
	end
end

--- get_matches returns a list of matches suitable for matchaddpos. All lines
-- and columns provided must be 1-indexed, and the values must be inclusive.
--
-- @param start_line the first line to highlight
-- @param start_col the optional column of the first line to highlight
-- @param end_line the last line to highlight
-- @param end_col the optional column of the last line to highlight
-- @param covered whether the line is covered
-- @return an array of tables each with a group, pos, and priority
local function get_matches(start_line, start_col, end_line, end_col, covered)
	local group = "CloverCovered"
	local priority = 10
	if not covered then
		group = "CloverUncovered"
		-- Some reporters such as jest let statements overlap. If that's the case,
		-- consider the uncovered statements to have a higher priority.
		priority = 15
	end

	local function new_match(pos)
		return {
			group = group,
			priority = priority,
			pos = pos,
		}
	end

	start_col = start_col or 1
	end_col = end_col or line_length(end_line)

	if start_line == end_line then
		local pos = { { start_line, start_col, end_col - start_col + 1 } }
		return { new_match(pos) }
	end

	local matches = {}

	local first_length = line_length(start_line) - start_col + 1
	local first_pos = { { start_line, start_col, first_length } }
	table.insert(matches, new_match(first_pos))

	for line = start_line + 1, end_line - 1, 1 do
		table.insert(matches, new_match({ line }))
	end

	local last_pos = { { end_line, 1, end_col } }
	table.insert(matches, new_match(last_pos))

	return matches
end

return {
	get_matches = get_matches,
	highlight = highlight,
	line_length = line_length,
}
