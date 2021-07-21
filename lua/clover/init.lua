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

	vim.fn.matchadd("Whitespace", [[\s\+]], 20)
	for line = 1, vim.fn.line("$"), 1 do
		vim.fn.matchaddpos("CloverIgnored", { line })
	end

	for _, match in ipairs(matches) do
		vim.fn.matchaddpos(match.group, match.pos)
	end
end

--- get_matches returns a list of matches suitable for matchaddpos.
--
-- @param start_line the first line to highlight
-- @param start_col the optional column of the first line to highlight
-- @param end_line the last line to highlight
-- @param end_col the optional column of the last line to highlight
-- @param covered whether the line is covered
local function get_matches(start_line, start_col, end_line, end_col, covered)
	local group = "CloverUncovered"
	if covered then
		group = "CloverCovered"
	end

	if not start_col or start_col == vim.NIL then
		start_col = 1
	end

	if not end_col or end_col == vim.NIL then
		end_col = line_length(cov["end"].line)
	end

	if start_line == end_line then
		local pos = { { start_line, start_col, end_col - start_col } }
		return { { group = group, pos = pos } }
	end

	local matches = {}

	local first_length = line_length(start_line) - start_col + 1
	local first_pos = { { start_line, start_col, first_length } }
	table.insert(matches, { group = group, pos = first_pos })

	for line = start_line + 1, end_line - 1, 1 do
		table.insert(matches, { group = group, pos = { line } })
	end

	local last_pos = { { end_line, 1, end_col - 1 } }
	table.insert(matches, { group = group, pos = last_pos })

	return matches
end

--- line_length returns the number of display cells a line occupies.
local function line_length(line_number)
	return vim.fn.strwidth(vim.fn.getline(line_number))
end

return {
	get_matches = get_matches,
	highlight = highlight,
	line_length = line_length,
}
