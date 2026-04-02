local M = {}

local merge_names_cache = nil

function M.resolve_label(label, fallback)
	if label and label ~= '' then
		return label
	end

	return fallback
end

local function git_output(args)
	local result = vim.fn.systemlist(args)
	if vim.v.shell_error ~= 0 or not result or result[1] == nil or result[1] == '' then
		return nil
	end

	return vim.trim(result[1])
end

function M.get_merge_names()
	if merge_names_cache ~= nil then
		return merge_names_cache
	end

	local merge_head = git_output({ 'git', 'rev-parse', '-q', '--verify', 'MERGE_HEAD' })
	if not merge_head then
		merge_names_cache = {}
		return merge_names_cache
	end

	merge_names_cache = {
		ours = 'HEAD',
		theirs = git_output({ 'git', 'name-rev', '--name-only', merge_head }),
	}

	return merge_names_cache
end

function M.compact_label(label, merge_names)
	if not label or label == '' then
		return label
	end

	if label:find('^%s*LOCAL') then
		return 'LOCAL'
	end

	local ref_name = label:match('%(([^()]*)%)%s*$')
	if label:find('^%s*OURS') then
		if ref_name and ref_name:find('HEAD') then
			return 'OURS (HEAD)'
		elseif merge_names and merge_names.ours then
			return 'OURS (' .. merge_names.ours .. ')'
		elseif ref_name and ref_name ~= '' then
			return 'OURS (' .. ref_name .. ')'
		end
		return 'OURS'
	end

	if label:find('^%s*THEIRS') then
		if ref_name and ref_name ~= '' then
			return 'THEIRS (' .. ref_name .. ')'
		elseif merge_names and merge_names.theirs then
			return 'THEIRS (' .. merge_names.theirs .. ')'
		end
		return 'THEIRS'
	end

	if label:find('^%s*BASE') then
		return 'BASE'
	end

	return vim.trim(label)
end

return M
