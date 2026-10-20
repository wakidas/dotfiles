package.path = table.concat({
	'./nvim/lua/?.lua',
	'./nvim/lua/?/init.lua',
	package.path,
}, ';')

local filepath = require('settings.functions.filepath')
local copied_path

vim.g.clipboard = {
	name = 'filepath-spec',
	copy = {
		['+'] = function(lines)
			copied_path = table.concat(lines, '\n')
		end,
	},
	paste = {
		['+'] = function()
			return { {}, 'v' }
		end,
	},
}

local function assert_eq(actual, expected, message)
	if actual ~= expected then
		error((message or 'assertion failed') .. '\nexpected: ' .. tostring(expected) .. '\nactual: ' .. tostring(actual))
	end
end

vim.api.nvim_buf_set_name(0, '/tmp/filepath-spec/example.lua')
filepath.copy_absolute_path()

assert_eq(copied_path, '/tmp/filepath-spec/example.lua', 'absolute path should be copied')
