package.path = table.concat({
	'./nvim/lua/?.lua',
	'./nvim/lua/?/init.lua',
	package.path,
}, ';')

local diffview_winbar = require('utils.diffview_winbar')

local function assert_eq(actual, expected, message)
	if actual ~= expected then
		error((message or 'assertion failed') .. '\nexpected: ' .. tostring(expected) .. '\nactual: ' .. tostring(actual))
	end
end

assert_eq(
	diffview_winbar.resolve_label(' OURS (Current changes)', 'fallback'),
	' OURS (Current changes)',
	'present labels should win'
)

assert_eq(
	diffview_winbar.resolve_label('', 'fallback'),
	'fallback',
	'empty labels should fall back'
)

assert_eq(
	diffview_winbar.resolve_label(nil, 'fallback'),
	'fallback',
	'nil labels should fall back'
)

assert_eq(
	diffview_winbar.compact_label(' OURS (Current changes) ffad876482 (HEAD -> conflict-repro)'),
	'OURS (HEAD)',
	'ours labels should be compacted to HEAD'
)

assert_eq(
	diffview_winbar.compact_label(' THEIRS (Incoming changes) d176a75c82 (conflict-branch-b)'),
	'THEIRS (conflict-branch-b)',
	'theirs labels should keep the incoming branch name'
)

assert_eq(
	diffview_winbar.compact_label(' THEIRS (Incoming changes) d176a75c82', {
		ours = 'HEAD',
		theirs = 'conflict-branch-b',
	}),
	'THEIRS (conflict-branch-b)',
	'theirs labels should fall back to merge names when refs are absent'
)

assert_eq(
	diffview_winbar.compact_label(' LOCAL (Working tree)'),
	'LOCAL',
	'local labels should be short'
)
