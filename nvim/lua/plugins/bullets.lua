-- bullets.vim: Markdown/テキストのリスト管理
-- Enterでリスト継続、Tab/Shift-Tabでインデント
return {
	"bullets-vim/bullets.vim",
	ft = { "markdown", "text", "gitcommit" },
	config = function()
		-- 行の途中でEnterを押した時もリストを継続するカスタム関数
		local function smart_list_enter()
			local line = vim.api.nvim_get_current_line()
			local col = vim.api.nvim_win_get_cursor(0)[2]
			local line_length = #line

			-- 行末の場合はbullets.vimのデフォルト動作
			if col >= line_length then
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes("<Plug>(bullets-newline)", true, true, true),
					"n",
					false
				)
				return
			end

			-- リストパターンを検出（-, *, +, 番号付きリスト、チェックボックス）
			local indent, bullet = line:match("^(%s*)([%-%*%+]%s+%[.%]%s*)")
			if not bullet then
				indent, bullet = line:match("^(%s*)([%-%*%+]%s+)")
			end
			if not bullet then
				indent, bullet = line:match("^(%s*)(%d+[%.%)]%s+)")
			end

			-- リストでない場合は通常の改行
			if not bullet then
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes("<CR>", true, true, true),
					"n",
					false
				)
				return
			end

			-- カーソル以降のテキストを取得
			local after_cursor = line:sub(col + 1)
			-- カーソルまでのテキストを設定
			local before_cursor = line:sub(1, col)

			-- 番号付きリストの場合は次の番号を計算
			local new_bullet = bullet
			local num = bullet:match("^(%d+)")
			if num then
				new_bullet = tostring(tonumber(num) + 1) .. bullet:sub(#num + 1)
			end

			-- vim.scheduleで非同期実行
			vim.schedule(function()
				-- 現在行を更新
				vim.api.nvim_set_current_line(before_cursor)
				local row = vim.api.nvim_win_get_cursor(0)[1]

				-- 新しいリスト項目を挿入
				local new_line = indent .. new_bullet .. after_cursor
				vim.api.nvim_buf_set_lines(0, row, row, false, { new_line })
				-- カーソルを新しい行のテキスト開始位置に移動
				vim.api.nvim_win_set_cursor(0, { row + 1, #indent + #new_bullet })
			end)
		end

		-- グローバルに関数を登録
		_G.smart_list_enter = smart_list_enter

		-- Markdown用のバッファローカルマッピング（nvim-cmpより優先）
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "markdown", "text", "gitcommit" },
			callback = function()
				local opts = { buffer = true, silent = true }
				-- インサートモードでTab/Shift-Tabでインデント
				vim.keymap.set("i", "<Tab>", "<Plug>(bullets-demote)", opts)
				vim.keymap.set("i", "<S-Tab>", "<Plug>(bullets-promote)", opts)
				-- Enterでスマートリスト継続
				vim.keymap.set("i", "<CR>", smart_list_enter, opts)
				-- ノーマルモードでoでリスト継続
				vim.keymap.set("n", "o", "<Plug>(bullets-newline)", opts)
			end,
		})
	end,
	init = function()
		-- 特定のファイルタイプで有効化
		vim.g.bullets_enabled_file_types = {
			"markdown",
			"text",
			"gitcommit",
		}

		-- 使用する箇条書きの種類（順序付き）
		vim.g.bullets_outline_levels = { "ROM", "ABC", "num", "abc", "rom", "std-", "std*", "std+" }

		-- 番号付きリストの自動再番号付けを有効化
		vim.g.bullets_renumber_on_change = 1

		-- 行が空になったときに箇条書き記号を削除
		vim.g.bullets_delete_last_bullet_if_empty = 1

		-- デフォルトのマッピングを無効化（カスタムマッピングを設定）
		vim.g.bullets_set_mappings = 0

		-- ネストしたチェックボックス
		vim.g.bullets_nested_checkboxes = 1

		-- カスタムキーマッピング
		vim.g.bullets_custom_mappings = {
			{ "imap", "<cr>", "<Plug>(bullets-newline)" },
			{ "inoremap", "<C-cr>", "<cr>" },
			{ "nmap", "o", "<Plug>(bullets-newline)" },
			{ "vmap", "gN", "<Plug>(bullets-renumber)" },
			{ "nmap", "gN", "<Plug>(bullets-renumber)" },
			{ "nmap", "<leader>x", "<Plug>(bullets-toggle-checkbox)" },
			{ "imap", "<Tab>", "<Plug>(bullets-demote)" },
			{ "nmap", ">>", "<Plug>(bullets-demote)" },
			{ "vmap", ">", "<Plug>(bullets-demote)" },
			{ "imap", "<S-Tab>", "<Plug>(bullets-promote)" },
			{ "nmap", "<<", "<Plug>(bullets-promote)" },
			{ "vmap", "<", "<Plug>(bullets-promote)" },
		}
	end,
}
