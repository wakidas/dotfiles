local M = {}

local function normalize(path)
	if not path or path == "" then
		return nil
	end
	local full_path = vim.fn.fnamemodify(path, ":p")
	if vim.fs and vim.fs.normalize then
		return vim.fs.normalize(full_path)
	end
	return full_path
end

local function starts_with(str, prefix)
	if vim.startswith then
		return vim.startswith(str, prefix)
	end
	return str:sub(1, #prefix) == prefix
end

local function collect_recent_paths()
	local cwd = normalize(vim.fn.getcwd())
	if not cwd then
		return {}, {}, nil
	end

	local sep = package.config:sub(1, 1)
	local prefix = cwd .. sep
	local seen = {}
	local recent = {}

	for _, path in ipairs(vim.v.oldfiles) do
		local normalized = normalize(path)
		if normalized and vim.fn.filereadable(normalized) == 1 and not seen[normalized] then
			if normalized == cwd or starts_with(normalized, prefix) then
				table.insert(recent, normalized)
				seen[normalized] = true
			end
		end
	end

	return recent, seen, cwd
end

local function collect_project_files(cwd, seen)
	if not cwd then
		return {}
	end

	local sep = package.config:sub(1, 1)
	local stack = { cwd }
	local others = {}

	while #stack > 0 do
		local dir = table.remove(stack)
		local iter, dir_obj = vim.fs.dir(dir)
		if iter then
			for name, type in iter, dir_obj do
				if name ~= "." and name ~= ".." then
					local path = dir .. sep .. name
					if type == "directory" then
						stack[#stack + 1] = path
					elseif type == "file" then
						local normalized = normalize(path)
						if normalized and vim.fn.filereadable(normalized) == 1 and not seen[normalized] then
							seen[normalized] = true
							table.insert(others, normalized)
						end
					end
				end
			end
		end
	end

	table.sort(others)
	return others
end

function M.open_project_recent()
	local ok = pcall(require, "telescope")
	if not ok then
		vim.notify("Telescope が読み込めません", vim.log.levels.ERROR)
		return
	end

	local recent, seen, cwd = collect_recent_paths()
	if not cwd then
		require("telescope.builtin").find_files()
		return
	end

	local others = collect_project_files(cwd, seen)
	local results = {}

	vim.list_extend(results, recent)
	vim.list_extend(results, others)

	if #results == 0 then
		vim.notify("現在のプロジェクトには最近開いたファイルがありません", vim.log.levels.INFO)
		require("telescope.builtin").find_files({ cwd = cwd })
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local make_entry = require("telescope.make_entry")

	pickers.new({}, {
		prompt_title = "Recent project files",
		cwd = cwd,
		finder = finders.new_table({
			results = results,
			entry_maker = make_entry.gen_from_file({}),
		}),
		previewer = conf.file_previewer({}),
		sorter = conf.file_sorter({}),
	}):find()
end

return M
