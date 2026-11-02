vim.o.ignorecase = true
vim.o.smartcase = true
vim.wo.number = true
vim.wo.scrolloff = 8
vim.wo.sidescrolloff = 8
vim.o.incsearch = true
vim.wo.relativenumber = true
vim.wo.nu = true
vim.o.hlsearch = false
vim.o.errorbells = false
vim.o.hidden = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.mouse = "a"
vim.wo.wrap = false
vim.o.expandtab = true

vim.g.NERDCreateDefaultMappings = 0
vim.g.mapleader = " "
vim.lsp.inlay_hint.enable()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	--{ 'neoclide/coc.nvim',            branch = 'master',                  build = 'yarn install --frozen-lockfile' },
	--{ 'junegunn/fzf',      build = ':call fzf#install()' },
	--'junegunn/fzf.vim',
	'neovim/nvim-lspconfig',
	{
		'milanglacier/minuet-ai.nvim',
		config = function()
			require('minuet').setup {
				provider = 'openai_fim_compatible',
				request_timeout = 20,
				n_completions = 1,
				context_window = 2048,
				provider_options = {
					openai_fim_compatible = {
						-- For Windows users, TERM may not be present in environment variables.
						-- Consider using APPDATA instead.
						api_key = 'TERM',
						name = 'Ollama',
						end_point = 'http://localhost:11434/v1/completions',
						model = 'qwen2.5-coder:7b',
						optional = {
							max_tokens = 56,
							top_p = 0.9,
						},
					},
				},
			}
		end,
	},
	--{ 'tzachar/cmp-ai',   dependencies = 'nvim-lua/plenary.nvim' },
	{ 'hrsh7th/nvim-cmp' },
	'hrsh7th/cmp-nvim-lsp',
	{
		'mrcjkb/rustaceanvim',
		version = '^9',
		config = function()
			vim.g.rustaceanvim = {
				server = {
					default_settings = {
						-- rust-analyzer language server configuration
						['rust-analyzer'] = {
							cargo = {
								allFeatures = true,
							},
						},
					},
				},
			}
		end,
		lazy = false
	},
	--'mikelue/vim-maven-plugin',
	'vim-test/vim-test',
	'tpope/vim-dispatch',
	{
		"L3MON4D3/LuaSnip",
		version = "2.*",
		build = "make install_jsregexp"
	},
	{
		'windwp/nvim-autopairs',
		event = "InsertEnter",
		opts = {} -- this is equalent to setup({}) function
	},
	{
		'nvim-telescope/telescope.nvim',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	{
		'nvimtools/none-ls.nvim',
		dependencies = { 'nvim-lua/plenary.nvim', 'nvimtools/none-ls-extras.nvim' },
	},
	'mfussenegger/nvim-jdtls',
	'gruvbox-community/gruvbox',
	'tpope/vim-fugitive',
	'tpope/vim-surround',
	'airblade/vim-gitgutter',
	{
		'preservim/nerdcommenter',
		config = function()
			function map(modes, target, combo)
				for _, mode in pairs(modes) do
					vim.keymap.set({ mode }, "<leader>" .. combo,
						":call nerdcommenter#Comment('" .. mode .. "', '" .. target .. "')<CR>")
				end
			end

			map({ "x", "n" }, "Comment", "cc")
			map({ "x", "n" }, "Uncomment", "cu")
			map({ "x", "n" }, "Toggle", "c<space>")
		end,
	},
	-- Plug 'hsanson/vim-android'
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
	--'rust-lang/rust.vim',
	-- "Plug 'neovim/nvim-lspconfig'
	--'tpope/vim-vinegar',
	-- "Plug 'simrat39/rust-tools.nvim'
	'mfussenegger/nvim-dap',
	--{ 'evanleck/vim-svelte', event = 'BufEnter *.svelte' },
	--'sheerun/vim-polyglot',
	--{ 'DingDean/wgsl.vim',   event = 'BufEnter *.wgsl' },
	--'tikhomirov/vim-glsl',
	-- Plug 'posva/vim-vue'
	-- Plug 'hashivim/vim-terraform'
	-- Plug 'leafgarland/typescript-vim'
	'lambdalisue/suda.vim',
	{ 'dinhhuy258/vim-database',         branch = 'master',  build = ':UpdateRemotePlugins' },
	{
		'nvim-lualine/lualine.nvim',
		dependencies = {
			'kyazdani42/nvim-web-devicons',
		}
	},
	-- " If you want to have icons in your statusline choose one of these
	'vinnymeller/swagger-preview.nvim',
	--'elkowar/yuck.vim',
	'wannesm/wmgraphviz.vim',
	{
		"arborist-ts/arborist.nvim",
		config = function()
			require("arborist").setup({
				install_popular = false,
			})
		end
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		requires = { { "nvim-lua/plenary.nvim" } }
	},
	{
		"David-Kunz/gen.nvim",
		opts = {
			model = "qwen2.5-coder:7b", -- The default model to use.
			quit_map = "q",             -- set keymap to close the response window
			retry_map = "<c-r>",        -- set keymap to re-send the current prompt
			accept_map = "<c-cr>",      -- set keymap to replace the previous selection with the last result
			display_mode = "float",     -- The display mode. Can be "float" or "split".
			host = "localhost",
			port = "11434",
			show_prompt = false,   -- Shows the Prompt submitted to Ollama.
			show_model = false,    -- Displays which model you are using at the beginning of your chat session.
			no_auto_close = false, -- Never closes the window automatically.
			init = function(options)
				--pcall(io.popen, "ollama serve > /dev/null 2>&1 &")
			end,
			-- Function to initialize Ollama
			command = function(options)
				local body = { model = options.model, stream = true }
				return "curl --silent --no-buffer -X POST http://" ..
					options.host .. ":" .. options.port .. "/api/chat -d $body"
			end,
			-- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
			-- This can also be a lua function returning a command string, with options as the input parameter.
			-- The executed command must return a JSON object with { response, context }
			-- (context property is optional).
			--list_models = '<omitted lua function>', -- Retrieves a list of model names
			result_filetype = "markdown",
			debug = false -- Prints errors and the command which is run.
		}
	},
	{
		'linrongbin16/lsp-progress.nvim',
		config = function()
			require('lsp-progress').setup()
		end
	},
	{
		'Joakker/lua-json5',
		build = './install.sh'
	},
	{
		"aznhe21/actions-preview.nvim",
		config = function()
			vim.keymap.set({ "v", "n" }, "<leader>ca", require("actions-preview").code_actions)
		end,
	},
	{
		'jmbuhr/otter.nvim',
		opts = {},
	},
	{
		"seblyng/roslyn.nvim",
		ft = "cs",
		---@module 'roslyn.config'
		---@type RoslynNvimConfig
		opts = {
			-- your configuration comes here; leave empty for default settings
		}
	},
	{
		'stevearc/oil.nvim',
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {},
		-- Optional dependencies
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
		-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
		lazy = false,
		config = function()
			vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
		end,
	},
	{
		'mbbill/undotree',
		config = function()
			vim.keymap.set("n", "<C-u>", "<CMD>UndotreeToggle<CR>", { desc = "Toggle UndoTree Panel" })
		end,
	},
	'kalafut/vim-taskjuggler',
})

-- TODO: find fix for nixos missing json5 lua lib
--require('dap.ext.vscode').json_decode = require 'json5'.parse

vim.g.gitgutter_map_keys = 0

local null_ls = require 'null-ls'

null_ls.setup({
	sources = {
		null_ls.builtins.formatting.biome.with({
			filetypes = {
				"javascript", "typescript", "javascriptreact", "typescriptreact", "css", "scss", "html"
			},
		}),
		null_ls.builtins.formatting.prettier.with({
			filetypes = {
				"javascript", "typescript", "javascriptreact", "typescriptreact", "css", "scss", "html",
				"json", "yaml",
				"markdown", "graphql", "md", "txt",
				"java", "toml",
			},
		}),
		require('none-ls.formatting.ruff_format'),
		--null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.pg_format,
		null_ls.builtins.formatting.nixfmt,
		--null_ls.builtins.diagnostics.sqlfluff.with({
		--extra_args = { "--dialect", "postgres" }, -- change to your dialect
		--}),
	},
	debug = false,
})

local ls = require 'luasnip'
-- Set up LuaSnip
vim.keymap.set({ "i" }, "<C-K>", function() ls.expand() end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-L>", function() ls.jump(1) end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-J>", function() ls.jump(-1) end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-E>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, { silent = true })


-- Set up nvim-cmp.
local cmp = require 'cmp'

cmp.setup({
	snippet = {
		-- REQUIRED - you must specify a snippet engine
		expand = function(args)
			--vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
			require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
			-- require('snippy').expand_snippet(args.body) -- For `snippy` users.
			-- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
		end,
	},
	window = {
		-- completion = cmp.config.window.bordered(),
		-- documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		['<C-b>'] = cmp.mapping.scroll_docs(-4),
		['<C-f>'] = cmp.mapping.scroll_docs(4),
		['<C-j>'] = cmp.mapping.select_next_item(),
		['<C-k>'] = cmp.mapping.select_prev_item(),
		['<C-Space>'] = cmp.mapping.complete(),
		["<C-x>"] = require('minuet').make_cmp_map(),
		['<C-e>'] = cmp.mapping.abort(),
		['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	}),
	sources = cmp.config.sources({
		{ name = 'nvim_lsp' },
		--{ name = 'vsnip' }, -- For vsnip users.
		{ name = 'luasnip' }, -- For luasnip users.
		-- { name = 'ultisnips' }, -- For ultisnips users.
		-- { name = 'snippy' }, -- For snippy users.
	}, {
		{ name = 'buffer' },
	}),
	performance = {
		fetching_timeout = 10000,
	},
})


-- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
local capabilities = require('cmp_nvim_lsp').default_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

function enable_lsp(name, config)
	config = config or { capabilities = capabilities }
	vim.lsp.config(name, config)
	vim.lsp.enable(name)
end

enable_lsp("basedpyright")
enable_lsp("lua_ls", {
	capabilities = capabilities,
	on_init = function(client)
		if client.workspace_folders then
			local path = client.workspace_folders[1].name
			if
				path ~= vim.fn.stdpath('config')
				and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
			then
				return
			end
		end

		client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
			runtime = {
				version = 'LuaJIT',
				path = {
					'lua/?.lua',
					'lua/?/init.lua',
				},
			},
			-- Make the server aware of Neovim runtime files
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME
				}
			}
		})
	end,
	settings = {
		Lua = {}
	}
})
enable_lsp("ts_ls", {
	on_init = function(client)
		client.server_capabilities.documentFormattingProvider = false
	end,
	capabilities = capabilities
})
enable_lsp("clangd", {
	capabilities = capabilities,
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }, -- exclude "proto".
})
enable_lsp("terraformls")
enable_lsp("r_language_server")
enable_lsp("arduino_language_server")
enable_lsp("bashls")
enable_lsp("cssls", {})
enable_lsp("gopls")
enable_lsp("nixd")
enable_lsp("html")
--lspconfig.java_language_server.setup {}
--lspconfig.jdtls.setup {}

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('UserLspConfig', {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local opts = { buffer = ev.buf }
		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
		vim.keymap.set('n', 'L', vim.diagnostic.open_float, opts)
		vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
		vim.keymap.set('n', '<C-K>', vim.lsp.buf.signature_help, opts)
		vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
		vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
		vim.keymap.set('n', '<space>wl', function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, opts)
		vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
		vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
		--vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
		vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
		vim.keymap.set('n', '<A-F>', function()
			vim.lsp.buf.format { async = true }
		end, opts)
		vim.keymap.set('v', '<A-F>', function()
			vim.lsp.buf.format {
				async = true,
				range = {
					["start"] = vim.api.nvim_buf_get_mark(0, "<"),
					["end"] = vim.api.nvim_buf_get_mark(0, ">"),
				}
			}
		end, opts)
	end,
})

local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
vim.keymap.set("n", "<space>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.cmd "colorscheme gruvbox"

vim.g.coc_global_extensions = {
	'coc-snippets',
	'coc-pairs',
	'coc-json',
	'coc-prettier',
	'coc-clangd',
	'coc-java',
	'coc-tsserver',
	-- 'coc-rls',
	'coc-pyright',
	'coc-rust-analyzer',
	'coc-flutter',
	'coc-emmet',
	'coc-xml',
	'coc-sql',
	'coc-svelte',
	'@yaegassy/coc-tailwindcss3',
	'coc-eslint',
	'coc-lua'
}

-- let g:netrw_keepdir=0
vim.g.netrw_banner = 0
-- let g:netrw_keepj=""

-- lua require('rust-tools').setup({})

--  Use <c-space> to trigger completion.

--vim.keymap.set('i', '<c-space>', 'coc#refresh()', { expr = true, noremap = true, silent = true })


-- " Use tab for trigger completion with characters ahead and navigate.
-- " Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
-- inoremap <silent><expr> <TAB>
--\ pumvisible() ? coc#pum#next(1) :
--\ <SID>check_back_space() ? "\<TAB>" :
--\ coc#refresh()

-- "let g:coc_snippet_next = '<TAB>'
-- "let g:coc_snippet_prev = '<S-TAB>'
-- inoremap <expr><S-TAB> pumvisible() ? coc#pum#prev(1) : "\<C-h>"


--function _G.check_back_space()
--local col = fn.col('.') - 1
--if col == 0 or fn.getline('.'):sub(col, col):match('%s') then
--return true
--else
--return false
--end
--end

--vim.keymap.set('v', '<C-j>', '<Plug>(coc-snippets-select)')

--vim.keymap.set('n', '<A-F>', '<Plug>(coc-format)', { silent = true })

--vim.keymap.set('i', '<cr>', 'coc#pum#visible() ? coc#pum#confirm() : "<CR>"', { expr = true, silent = true })
--vim.keymap.set('n', '<leader>a', '<Plug>(coc-codeaction)')

--vim.keymap.set('n', '[c', '<Plug>(coc-diagnostic-prev-error)', { silent = true })
--vim.keymap.set('n', ']c', '<Plug>(coc-diagnostic-next-error)', { silent = true })
--vim.keymap.set('n', '<leader>rn', '<Plug>(coc-rename)')

vim.g.gradle_path = "/usr/bin/gradle"
vim.g.android_sdk_path = "/home/alan/Android/Sdk"

--  Remap keys for gotos
--vim.keymap.set('n', 'gd', '<Plug>(coc-definition)', { silent = true })
--vim.keymap.set('n', 'gy', '<Plug>(coc-type-definition)', { silent = true })
--vim.keymap.set('n', 'gi', '<Plug>(coc-implementation)', { silent = true })
--vim.keymap.set('n', 'gr', '<Plug>(coc-references)', { silent = true })

-- highlight LineNr term=bold ctermfg=grey
-- highlight CocInlayHint guibg=Red guifg=Blue ctermbg=Red ctermfg=Blue

--  VSCode like line moving
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv", { noremap = true })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv", { noremap = true })
vim.keymap.set('n', '<A-k>', ":m -2<CR>", { noremap = true })
vim.keymap.set('n', '<A-j>', ":m +1<CR>", { noremap = true })


-- vnoremap {{ "sc{<C-r>s}<Esc>
-- vnoremap [[ "sc[<C-r>s]<Esc>
-- vnoremap (( "sc(<C-r>s)<Esc>
-- vnoremap "" "sc"<C-r>s"<Esc>
-- vnoremap '' "sc'<C-r>s'<Esc>

-- nmap <C-e> :GFiles<CR>
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', function()
	local opts = {} -- define here if you want to define something
	vim.fn.system('git rev-parse --is-inside-work-tree')
	--if vim.v.shell_error == 0 then
	--require "telescope.builtin".git_files(opts)
	--else
	require "telescope.builtin".find_files(opts)
	--end
end, {})
vim.keymap.set('n', '<leader>rg', builtin.live_grep, {})

local dap = require('dap')
dap.adapters.lldb = {
	type = 'executable',
	command = '/usr/bin/lldb-vscode',
	name = "lldb"
}
dap.adapters.c = {
	type = 'executable',
	command = '/usr/bin/lldb-vscode',
	name = "c"
}
dap.configurations.rust = {
	{
		name = "Launch Debug",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {},
	},
}
dap.configurations.c = {
	{
		name = "launch",
		type = "lldb",
		program = function()
			return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
		end,
		request = "launch",
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {},
	},
}
vim.fn.sign_define('DapBreakpoint', { text = '🟥', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '⭐️', texthl = '', linehl = '', numhl = '' })


function define_dap_remap(mode, key, func_name)
	vim.keymap.set('n', '<leader>' .. key, ":lua " .. func_name .. "<CR>", { noremap = true })
end

define_dap_remap('n', 'dh', "require'dap'.toggle_breakpoint()")
define_dap_remap('n', 'k', "require'dap'.step_out()")
define_dap_remap('n', 'l', "require'dap'.step_into()")
define_dap_remap('n', 'j', "require'dap'.step_over()")
define_dap_remap('n', 'ds', "require'dap'.close()")
define_dap_remap('n', 'dn', "require'dap'.continue()")
define_dap_remap('n', 'dk', "require'dap'.up()")
define_dap_remap('n', 'dj', "require'dap'.down()")
define_dap_remap('n', 'd_', "require'dap'.disconnect();require'dap'.close();require'dap'.run_last()")
define_dap_remap('n', 'dr', "require'dap'.repl.open({}, 'vsplit')")
define_dap_remap('n', 'di', "require'dap.ui.widgets'.hover()")
define_dap_remap('v', 'di', "require'dap.ui.variables'.visual_hover()")
define_dap_remap('v', 'd?', "require'dap.ui.variables'.scopes()")
-- nnoremap <leader>de :lua require'dap'.set_exception_breakpoints({"all"})<CR>
-- nnoremap <leader>da :lua require'debugHelper'.attach()<CR>
-- nnoremap <leader>dA :lua require'debugHelper'.attachToRemote()<CR>
-- nnoremap <leader>di :lua require'dap.ui.widgets'.hover()<CR>
-- nnoremap <leader>d? :lua local widgets=require'dap.ui.widgets';widgets.centered_float(widgets.scopes)<CR>

vim.g.fzf_action = {
	['ctrl-t'] = 'tab split',
	['ctrl-x'] = 'split',
	['ctrl-v'] = 'vsplit',
	['ctrl-q'] = 'fill_quickfix'
}

--vim.api.nvim_create_user_command('Prettier', 'Prettier :CocCommand prettier.formatFile', {})

vim.keymap.set('n', '<C-J>', '<C-W><C-J>')
vim.keymap.set('n', '<C-K>', '<C-W><C-K>')
vim.keymap.set('n', '<C-L>', '<C-W><C-L>')
vim.keymap.set('n', '<C-H>', '<C-W><C-H>')

vim.keymap.set('n', '<C-w>l', '<C-w>v<C-l>')
vim.keymap.set('n', '<C-w>h', '<C-w>v')
vim.keymap.set('n', '<C-w>j', '<C-w>s<C-j>')
vim.keymap.set('n', '<C-w>k', '<C-w>s')

vim.keymap.set('x', 'p', 'pgvy', { noremap = true })

vim.keymap.set('n', '<A-h>', ':tabp<CR>', { noremap = true })
vim.keymap.set('n', '<A-l>', ':tabn<CR>', { noremap = true })
vim.keymap.set('n', '<C-t>', ':tab split<CR>', { noremap = true })

-- tnoremap <Esc> <C-\><C-n>
-- tnoremap <C-c> <C-\><C-n>

vim.g.omni_sql_no_default_maps = 1

vim.keymap.set('n', '<Leader>cp',
	[[:clear<bar>silent exec "!cp '%:p' '%:p:h/%:t:r-copy.%:e'"<bar>redraw<bar>echo "Copied " . expand('%:t') . ' to ' . expand('%:t:r') . '-copy.' . expand('%:e')<cr>]],
	{ noremap = true, silent = true })

require('swagger-preview').setup {
	-- The port to run the preview server on
	port = 8000,
	-- The host to run the preview server on
	host = "localhost",
}

require('lualine').setup {
	options = {
		path = 1
	},
	sections = {
		lualine_a = {
			function()
				-- invoke `progress` here.
				return require('lsp-progress').progress()
			end,
			'bo:filetype',
		}
	}
}

require("oil").setup()

vim.lsp.config("roslyn", {
	cmd = {
		"Microsoft.CodeAnalysis.LanguageServer",
		"--logLevel=Information",
		"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.log.get_filename()),
		"--stdio",
	},
})

-- vim.opt.statusline^=%{coc#status()}

--vim.api.nvim_create_autocmd('User', { pattern = 'CocStatusChange', callback = 'redrawstatus' })
