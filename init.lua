-- init.lua: Minimal Neovim Config with LSP + Autocomplete + Smart IO + Terminal
-- ============================================================================

-- Leader key
vim.g.mapleader = " "

-- General options
local opt = vim.opt
opt.splitright = true
opt.splitbelow = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.wrap = false
opt.smartindent = true
opt.swapfile = false
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.expandtab = true

-- =========================
-- Plugin Management (lazy.nvim)
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Editing
  { "tpope/vim-surround" },
  { "windwp/nvim-autopairs" },
  { "sheerun/vim-polyglot" },

  -- UI / Colorscheme
  { "morhetz/gruvbox" },
  { "itchyny/lightline.vim" },

  -- File Explorer
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },

  -- Fuzzy Finder
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Git
  { "lewis6991/gitsigns.nvim" },
  { "tpope/vim-fugitive" },

  -- LSP + Autocomplete
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- Terminal
  { "akinsho/toggleterm.nvim" },
})

-- =========================
-- Colorscheme
-- =========================
vim.cmd("colorscheme gruvbox")
vim.g.lightline = { colorscheme = "wombat" }

-- =========================
-- gitsigns
-- =========================
require("gitsigns").setup()

-- =========================
-- nvim-tree
-- =========================
require("nvim-tree").setup()

-- =========================
-- toggleterm
-- =========================
require("toggleterm").setup()

-- =========================
-- LSP + Autocomplete (new API)
-- =========================
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "pyright", "clangd", "lua_ls" },
})

local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
  },
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local function on_attach(client, bufnr)
  local buf_map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true, desc = desc })
  end
  buf_map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
  buf_map("n", "K", vim.lsp.buf.hover, "Hover Docs")
  buf_map("n", "gr", vim.lsp.buf.references, "References")
  buf_map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
  buf_map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
end

-- New API: vim.lsp.config + vim.lsp.enable
for _, server in ipairs({ "pyright", "clangd", "lua_ls" }) do
  vim.lsp.config[server] = {
    capabilities = capabilities,
    on_attach = on_attach,
  }
  vim.lsp.enable(server)
end

-- =========================
-- Smart IO Buffers & Compile/Run
-- =========================
local MIO = {}

MIO.working_win = nil
MIO.working_file = nil
MIO.working_ft = nil
MIO.input_win = nil
MIO.output_win = nil

local function detect_command(ft, filename)
  if ft == "python" then
    return string.format("!cat input.file | python3 %s > output.file", filename)
  elseif ft == "cpp" then
    return string.format("!g++ %s -o %s.out && ./%s.out < input.file > output.file", filename, filename, filename)
  elseif ft == "c" then
    return string.format("!gcc %s -o %s.out && ./%s.out < input.file > output.file", filename, filename, filename)
  end
end

function MIO.setup_buffers()
  MIO.working_win = vim.api.nvim_get_current_win()
  MIO.working_file = vim.fn.expand("%")
  MIO.working_ft = vim.bo.filetype

  vim.cmd("vsplit input.file")
  MIO.input_win = vim.api.nvim_get_current_win()
  vim.cmd("vertical resize 60")
  vim.cmd("split output.file")
  MIO.output_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(MIO.input_win)
end

function MIO.close_buffers()
  if MIO.working_win then
    vim.api.nvim_set_current_win(MIO.working_win)
    vim.cmd("on")
  end
end

function MIO.jump_to_working()
  if MIO.working_win then
    vim.api.nvim_set_current_win(MIO.working_win)
  end
end

function MIO.compile_and_run()
  if not MIO.working_file or not MIO.working_ft then
    vim.notify("No working file detected!", vim.log.levels.WARN)
    return
  end
  local cmd = detect_command(MIO.working_ft, MIO.working_file)
  if cmd then
    vim.cmd(cmd)
    vim.notify("Ran " .. MIO.working_file .. " as " .. MIO.working_ft, vim.log.levels.INFO)
  else
    vim.notify("Unsupported filetype: " .. MIO.working_ft, vim.log.levels.ERROR)
  end
end

-- =========================
-- Keymaps
-- =========================
vim.keymap.set("n", "<leader>co", MIO.setup_buffers, { desc = "Open IO Buffers" })
vim.keymap.set("n", "<leader>cc", MIO.close_buffers, { desc = "Close IO Buffers" })
vim.keymap.set("n", "<leader>cr", MIO.compile_and_run, { desc = "Compile & Run" })
vim.keymap.set("n", "<leader>cj", MIO.jump_to_working, { desc = "Jump to Working Buffer" })

vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Live Grep" })
vim.keymap.set("n", "<leader>gt", ":ToggleTerm<CR>", { desc = "Toggle Terminal" })
vim.keymap.set("n", "<leader>tt", ":ToggleTerm direction=tab<CR>", { desc = "Terminal in new tab" })

