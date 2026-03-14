local keymap = vim.keymap.set
local autocmd = vim.api.nvim_create_autocmd

vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.cursorline = true

-- don't show the mode, since it's already in the status line
vim.opt.showmode = false
-- vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250

vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:,diff:╱]]
-- vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.opt.listchars = {
	tab = "│ ",
	leadmultispace = "│ ", -- Works on newer versions of Neovim
	-- multispace = '   │', -- Works on newer versions of Neovim
	-- or for older versions
	-- space = '·',
}
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.hlsearch = true
vim.opt.wrap = true

-- formatting
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.textwidth = 80

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = " ",
		},
	},
	virtual_text = true, -- show inline diagnostics
})

vim.cmd.colorscheme("catppuccin")
vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" }, { confirm = false })
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" }, { confirm = false })
-- INFO: mini.nvim
vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" }, { confirm = false })
require("mini.align").setup()
require("mini.visits").setup()
require("mini.bracketed").setup()
require("mini.bufremove").setup()
require("mini.clue").setup()
require("mini.cursorword").setup()
require("mini.diff").setup()
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()
require("mini.surround").setup()
require("mini.splitjoin").setup()
require("mini.notify").setup()
require("mini.statusline").setup({
	content = {
		active = function()
			local _, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
			local filename = MiniStatusline.section_filename({ trunc_width = 99999 }) -- never truncate
			local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
			local location = MiniStatusline.section_location({ trunc_width = 75 })

			return MiniStatusline.combine_groups({
				{ hl = "MiniStatuslineFilename", strings = { filename } },
				"%=", -- right align from here
			})
		end,
	},
})

require("mini.tabline").setup()

local treesitter_languages = {
	"lua",
	"c",
	"rust",
	"go",
}

require("nvim-treesitter").install(treesitter_languages)

vim.api.nvim_create_autocmd("FileType", {
	pattern = treesitter_languages,
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
		vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

vim.pack.add({ "https://github.com/saghen/blink.cmp" }, { confirm = false })

require("blink.cmp").setup({
	completion = {
		documentation = {
			auto_show = true,
		},
	},

	keymap = {
		-- these are the default blink keymaps
		["<C-n>"] = { "select_next", "fallback_to_mappings" },
		["<C-p>"] = { "select_prev", "fallback_to_mappings" },
		["<C-y>"] = { "select_and_accept", "fallback" },
		["<C-e>"] = { "cancel", "fallback" },

		["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
		["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
		["<CR>"] = { "select_and_accept", "fallback" },
		["<Esc>"] = { "cancel", "hide_documentation", "fallback" },

		["<C-space>"] = { "show", "show_documentation", "hide_documentation" },

		["<C-b>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },

		["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
	},

	fuzzy = {
		implementation = "lua",
	},
})

-- INFO: lsp server installation and configuration

-- lsp servers we want to use and their configuration
-- see `:h lspconfig-all` for available servers and their settings
local lsp_servers = {
	lua_ls = {
		-- https://luals.github.io/wiki/settings/ | `:h nvim_get_runtime_file`
		Lua = { workspace = { library = vim.api.nvim_get_runtime_file("lua", true) } },
	},
}

local function has_config(patterns)
	local buf_path = vim.api.nvim_buf_get_name(0)
	if buf_path == "" then
		return false
	end
	return #vim.fs.find(patterns, { upward = true, path = vim.fs.dirname(buf_path) }) > 0
end

local function is_biome_project()
	return has_config({ "biome.json", "biome.jsonc" })
end

local function is_eslint_project()
	return has_config({
		".eslintrc",
		".eslintrc.js",
		".eslintrc.cjs",
		".eslintrc.json",
		".eslintrc.yaml",
		".eslintrc.yml",
		"eslint.config.js",
		"eslint.config.mjs",
		"eslint.config.cjs",
		"eslint.config.ts",
	})
end

local function lsp_code_action(action)
	vim.lsp.buf.code_action({
		context = { only = { action }, diagnostics = {} },
		apply = true,
	})
end

local function ts_add_missing_imports()
	pcall(vim.cmd, "TypescriptAddMissingImports")
end

local function ts_organize_imports()
	pcall(vim.cmd, "TypescriptOrganizeImports")
	lsp_code_action("source.organizeImports")
	lsp_code_action("source.organizeImports.ts")
end

local function ts_fix_all()
	pcall(vim.cmd, "TypescriptFixAll")
	lsp_code_action("source.fixAll.ts")
end

local function ts_remove_unused()
	pcall(vim.cmd, "TypescriptRemoveUnused")
	lsp_code_action("source.removeUnusedImports")
end

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("AutoFixOnSave", { clear = true }),
	pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.json", "*.jsonc" },
	callback = function()
		ts_add_missing_imports()
		ts_organize_imports()
		ts_fix_all()

		if is_biome_project() and not is_eslint_project() then
			lsp_code_action("source.fixAll.biome")
		else
			pcall(vim.cmd, "EslintFixAll")
			pcall(vim.cmd, "LspEslintFixAll")
		end
	end,
})

autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
	callback = function(args)
		print('attack')
		local client = vim.lsp.get_client_by_id(args.data.client_id)

		if client:supports_method("textDocument/semanticTokens") then
			client.server_capabilities.semanticTokensProvider = nil
		end

		-- Add TypeScript move-to-file refactoring support
		-- if client then
		-- 	local signatureProvider = client.server_capabilities.signatureHelpProvider
		-- 	if signatureProvider and signatureProvider.triggerCharacters then
		-- 		require("gon.ui.signature").setup(client, args.buf)
		-- 	end
		-- end

		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = args.buf, desc = "LSP: " .. desc })
		end
		-- https://github.com/neovim/neovim/pull/19213
		local function on_list(options)
			vim.fn.setqflist({}, " ", options)
			vim.api.nvim_command("cfirst")
		end

		local bufopts = { noremap = true, silent = true }

		-- vim.keymap.set('n', 'gd', function()
		--   vim.lsp.buf.definition { on_list = on_list }
		-- end, bufopts)

		local function location_handler(_, result, ctx)
			vim.g.lsp_last_word = vim.fn.expand("<cword>")
			if result == nil or vim.tbl_isempty(result) then
				print(ctx.method, "No location found")
				return nil
			end
			local util = require("vim.lsp.util")
			if vim.tbl_islist(result) then
				if #result == 1 then
					util.jump_to_location(result[1])
				elseif #result > 1 then
					util.set_qflist(util.locations_to_items(result))
					-- require('plugins.fzf').quickfix(vim.fn.expand '<cword>')
					api.nvim_command("copen")
					api.nvim_command("wincmd p")
				end
			else
				util.jump_to_location(result)
			end
		end

		vim.lsp.handlers["textDocument/declaration"] = location_handler
		vim.lsp.handlers["textDocument/definition"] = location_handler
		vim.lsp.handlers["textDocument/typeDefinition"] = location_handler
		vim.lsp.handlers["textDocument/implementation"] = location_handler

		vim.keymap.set("n", "gD", function()
			vim.lsp.buf.declaration({ on_list = on_list })
		end, bufopts)
		vim.keymap.set("n", "gr", function()
			vim.lsp.buf.references(nil, { on_list = on_list })
		end, bufopts)
		-- vim.keymap.set('n', 'gi', function()
		--   vim.lsp.buf.implementation { on_list = on_list }
		-- end, bufopts)
		-- vim.keymap.set('n', 'gy', function()
		--   vim.lsp.buf.type_definition {}
		-- end, bufopts)

		map("<leader>rn", function()
			vim.lsp.buf.rename()
		end, "[R]e[n]ame")
		vim.keymap.set("n", "K", function()
			vim.lsp.buf.hover({ border = "rounded", title = " hover " })
		end, { desc = "Hover Documentation" })
		-- map('go', vim.diagnostic.open_float, 'Open diagnostic [o]verview')
		map("go", function()
			require("plugins.lsp.diagnostic").open_float_with_markdown()
		end, "Open diagnostic [o]verview with markdown")
		keymap({ "n", "x" }, "<leader>ac", vim.lsp.buf.code_action, {
			desc = "[C]ode [A]ction",
		})
		keymap("<leader>ai", ts_add_missing_imports, "Auto import all")
		map("<leader>ar", ts_remove_unused, "Remove unused")
		map("<leader>aI", ":TSLspImportCurrent<CR>", "Import current")
		map("<leader>ah", vim.lsp.buf.signature_help, "signature_help")
		vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, {
			noremap = true,
		})
		map("<leader>ae", function()
			pcall(vim.cmd, "EslintFixAll")
			pcall(vim.cmd, "LspEslintFixAll")
			vim.lsp.buf.code_action({
				async = false,
				context = { only = { "source.fixAll.biome" }, diagnostics = {} },
				timeout_ms = 1000,
				apply = true,
			})
		end, "eslint fix all")

		keymap("n", "]d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
		keymap("n", "[d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
		map("[e", function()
			vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
		end, "Next [e]rror")

		map("]e", function()
			vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
		end, "prev [e]rror")

		map("[w", function()
			vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
		end, "Next [w]arning")

		map("]w", function()
			vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
		end, "prev [w]arning")
	end,
})

vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig", -- default configs for lsps

	-- NOTE: if you'd rather install the lsps through your OS package manager you
	-- can delete the next three mason-related lines and their setup calls below.
	-- see `:h lsp-quickstart` for more details.
	"https://github.com/mason-org/mason.nvim", -- package manager
	"https://github.com/mason-org/mason-lspconfig.nvim", -- lspconfig bridge
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim", -- auto installer
}, { confirm = false })

require("mason").setup()
require("mason-lspconfig").setup()
require("mason-tool-installer").setup({
	ensure_installed = vim.tbl_keys(lsp_servers),
})

-- configure each lsp server on the table
-- to check what clients are attached to the current buffer, use
-- `:checkhealth vim.lsp`. to view default lsp keybindings, use `:h lsp-defaults`.
for server, config in pairs(lsp_servers) do
	vim.lsp.config(server, {
		settings = config,

		-- only create the keymaps if the server attaches successfully
		on_attach = function(_, bufnr)
			vim.keymap.set("n", "grd", vim.lsp.buf.definition, { buffer = bufnr, desc = "vim.lsp.buf.definition()" })

			vim.keymap.set("n", "grf", vim.lsp.buf.format, { buffer = bufnr, desc = "vim.lsp.buf.format()" })
		end,
	})
end

-- NOTE: if all you want is lsp + completion + highlighting, you're done.
-- the rest of the lines are just quality-of-life/appearance plugins and
-- can be removed.

-- INFO: fuzzy finder
vim.pack.add({
	"https://github.com/nvim-telescope/telescope.nvim",
}, { confirm = false })

local pickers = require("telescope.builtin")
require("telescope").setup({
	defaults = {
		generic_sorter = require("mini.fuzzy").get_telescope_sorter,
	},
})

-- INFO: git utils
vim.pack.add({ "https://github.com/nicolasgb/jj.nvim" }, { confirm = false })
require("jj").setup({})

vim.pack.add({ "https://github.com/ThePrimeagen/refactoring.nvim" }, { confirm = false })
require("refactoring").setup({})

local notify_many_keys = function(key)
	local lhs = string.rep(key, 5)
	local action = function()
		vim.notify("Too many " .. key)
	end
	require("mini.keymap").map_combo({ "n", "x" }, lhs, action)
end
notify_many_keys("h")
notify_many_keys("j")
notify_many_keys("k")
notify_many_keys("l")

-- keymaps
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")
keymap("n", "<leader>sp", pickers.builtin, { desc = "[S]earch Builtin [P]ickers" })
keymap("n", "\\p", pickers.buffers, { desc = "[S]earch [B]uffers" })
keymap("n", "<C-p>", pickers.find_files, { desc = "[S]earch [F]iles" })
keymap("n", "<leader>fw", pickers.grep_string, { desc = "[S]earch Current [W]ord" })
keymap("n", "<leader>fg", pickers.live_grep, { desc = "[S]earch by [G]rep" })
keymap("n", "<leader>ff", pickers.resume, { desc = "[S]earch [R]esume" })

keymap("n", "<leader>fh", pickers.help_tags, { desc = "[S]earch [H]elp" })
keymap("n", "<leader>fm", pickers.man_pages, { desc = "[S]earch [M]anuals" })
keymap("n", "<leader>e", function()
	MiniVisits.select_path()
end)

for i = 1, 9 do
	keymap("n", "<leader>b" .. i, function()
		vim.api.nvim_set_current_buf(vim.t.bufs[i])
	end, {
		desc = "Go to buffer " .. i,
	})
end

vim.keymap.del("n", "grr")
vim.keymap.del("n", "gri")
vim.keymap.del("n", "grn")
vim.keymap.del("n", "grt")
vim.keymap.del("n", "gra")

keymap("n", "<leader>gq", function()
	vim.cmd('cexpr system("git diff --check --relative")')
	vim.cmd("copen")
end, { desc = "Git conflicts to quickfix" })

vim.keymap.set({ "n", "x" }, "<leader>re", function()
	return require("refactoring").refactor("Extract Function")
end, { expr = true, desc = "Extract Function" })
vim.keymap.set({ "n", "x" }, "<leader>rf", function()
	return require("refactoring").refactor("Extract Function To File")
end, { expr = true, desc = "Extract Function To File" })
vim.keymap.set({ "n", "x" }, "<leader>rv", function()
	return require("refactoring").refactor("Extract Variable")
end, { expr = true, desc = "Extract Variable" })
vim.keymap.set({ "n", "x" }, "<leader>rI", function()
	return require("refactoring").refactor("Inline Function")
end, { expr = true, desc = "Inline Function" })
vim.keymap.set({ "n", "x" }, "<leader>ri", function()
	return require("refactoring").refactor("Inline Variable")
end, { expr = true, desc = "Inline Variable" })

vim.keymap.set({ "n", "x" }, "<leader>rbb", function()
	return require("refactoring").refactor("Extract Block")
end, { expr = true, desc = "Extract Block" })
vim.keymap.set({ "n", "x" }, "<leader>rbf", function()
	return require("refactoring").refactor("Extract Block To File")
end, { expr = true, desc = "Extract Block To File" })
