--- highlight produces highlights in a document based on matches passed.
--
-- @param matches an array of matches
-- @param matches.group the appropriate highlight group
-- @param matches.pos the positions as documented in matchaddpos
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

return {
	highlight = highlight,
}
