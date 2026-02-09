-- ========================================================================
-- 1. GLOBALS & LEADER KEY
-- ========================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ========================================================================
-- 2. BOOTSTRAP LAZY.NVIM
-- ========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- ========================================================================
-- 3. PLUGINS
-- ========================================================================
require("lazy").setup({

    -- ── THEME: Tokyonight (styled) ──────────────────────────────────────
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            style = "night",
            transparent = false,
            terminal_colors = true,
            styles = {
                comments  = { italic = true },
                keywords  = { italic = true },
                functions = {},
                variables = {},
                sidebars  = "dark",
                floats    = "dark",
            },
            -- Tweak specific highlight groups for a polished look
            on_highlights = function(hl, c)
                -- Popup menu (autocomplete) ── rounded, translucent feel
                hl.Pmenu        = { bg = c.bg_dark,    fg = c.fg }
                hl.PmenuSel     = { bg = c.blue0,      fg = c.fg,  bold = true }
                hl.PmenuSbar    = { bg = c.bg_dark }
                hl.PmenuThumb   = { bg = c.blue }

                -- Floating windows
                hl.FloatBorder  = { bg = c.bg_dark,    fg = c.blue }
                hl.NormalFloat  = { bg = c.bg_dark }

                -- CMP item kinds ── subtle colored icons
                hl.CmpItemAbbrMatch      = { fg = c.blue,    bold = true }
                hl.CmpItemAbbrMatchFuzzy = { fg = c.blue,    bold = true }
                hl.CmpItemKindFunction   = { fg = c.magenta }
                hl.CmpItemKindMethod     = { fg = c.magenta }
                hl.CmpItemKindVariable   = { fg = c.cyan }
                hl.CmpItemKindKeyword    = { fg = c.purple }
                hl.CmpItemKindSnippet    = { fg = c.green }
                hl.CmpItemKindText       = { fg = c.fg_dark }
                hl.CmpItemKindField      = { fg = c.green1 }
                hl.CmpItemKindProperty   = { fg = c.green1 }

                -- Bufferline bg blending
                hl.BufferLineBackground   = { bg = c.bg_dark }
                hl.BufferLineFill          = { bg = c.bg_dark }
            end,
        },
        config = function(_, opts)
            require("tokyonight").setup(opts)
            vim.cmd.colorscheme("tokyonight-night")
        end,
    },

    -- ── STATUSLINE: Lualine (pill / powerline look) ─────────────────────
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = function()
            local colors = require("tokyonight.colors").setup()
            return {
                options = {
                    theme = "tokyonight",
                    -- Rounded separators give the "pill" look
                    component_separators = { left = "", right = "" },
                    section_separators   = { left = "", right = "" },
                    globalstatus = true,
                    disabled_filetypes = { statusline = { "neo-tree" } },
                },
                sections = {
                    lualine_a = { { "mode", separator = { left = "", right = "" }, padding = 1 } },
                    lualine_b = { "branch", "diff" },
                    lualine_c = {
                        { "filename", path = 0, symbols = { modified = " +", readonly = " -", unnamed = "[No Name]" } },
                        { "diagnostics", sources = { "nvim_diagnostic" } },
                    },
                    lualine_x = { "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { { "location", separator = { left = "", right = "" }, padding = 1 } },
                },
            }
        end,
    },

    -- ── BUFFERLINE (tab-style buffer bar) ───────────────────────────────
    {
        "akinsho/bufferline.nvim",
        version = "*",
        event = "VeryLazy",
        opts = {
            options = {
                mode = "buffers",
                themable = true,
                -- Use plain text separators (no nerd font needed)
                separator_style = "thin",
                show_buffer_close_icons = true,
                show_close_icon = false,
                close_icon = "x",
                buffer_close_icon = "x",
                modified_icon = "+",
                left_trunc_marker = "<",
                right_trunc_marker = ">",
                indicator = { style = "underline" },
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(count, level)
                    local icon = level:match("error") and "E" or "W"
                    return " " .. icon .. count
                end,
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "Explorer",
                        text_align = "center",
                        separator = true,
                    },
                },
            },
        },
    },

    -- ── FILE FINDER: Telescope ──────────────────────────────────────────
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.6",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- ── FILE EXPLORER: Neo-tree ─────────────────────────────────────────
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("neo-tree").setup({
                window = { width = 30 },
                default_component_configs = {
                    icon = {
                        folder_closed = ">",
                        folder_open   = "v",
                        folder_empty  = "-",
                        default       = "*",
                    },
                    git_status = {
                        symbols = {
                            added     = "+",
                            modified  = "~",
                            deleted   = "x",
                            renamed   = "r",
                            untracked = "?",
                            ignored   = ".",
                            unstaged  = "U",
                            staged    = "S",
                            conflict  = "!",
                        },
                    },
                },
            })
        end,
    },

    -- ── TREESITTER (Syntax Highlighting) ────────────────────────────────
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            local status_ok, configs = pcall(require, "nvim-treesitter.configs")
            if not status_ok then return end

            configs.setup({
                ensure_installed = {
                    "lua", "vim", "vimdoc",
                    "go", "gomod", "rust", "toml",
                    "python", "json", "yaml", "bash",
                },
                sync_install = false,
                auto_install = true,
                highlight = { enable = true },
                indent   = { enable = true },
            })
        end,
    },

    -- ── AUTOPAIRS ───────────────────────────────────────────────────────
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    -- ── LSP & COMPLETION ────────────────────────────────────────────────
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "williamboman/mason.nvim", config = true },
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            { "j-hui/fidget.nvim", opts = {} },
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-buffer",
            "onsails/lspkind.nvim",   -- adds VS-Code-style kind icons (text, no nerd font)
        },
        config = function()
            require("mason").setup()

            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            require("mason-lspconfig").setup({
                ensure_installed = {
                    "gopls",
                    "rust_analyzer",
                    "pyright",
                    "lua_ls",
                },
                handlers = {
                    function(server_name)
                        require("lspconfig")[server_name].setup({
                            capabilities = capabilities,
                        })
                    end,
                },
            })

            -- ── CMP (autocomplete popup) styling ────────────────────────
            local cmp = require("cmp")
            local lspkind = require("lspkind")

            cmp.setup({
                window = {
                    completion = cmp.config.window.bordered({
                        border = "rounded",
                        winhighlight = "Normal:Pmenu,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
                        col_offset = -1,
                        side_padding = 1,
                    }),
                    documentation = cmp.config.window.bordered({
                        border = "rounded",
                        winhighlight = "Normal:Pmenu,FloatBorder:FloatBorder",
                    }),
                },
                formatting = {
                    fields = { "kind", "abbr", "menu" },
                    format = lspkind.cmp_format({
                        mode = "symbol_text",      -- "symbol" | "text" | "symbol_text"
                        maxwidth = 50,
                        ellipsis_char = "..",
                        -- Use text symbols instead of nerd font icons
                        symbol_map = {
                            Text          = "Tx",
                            Method        = "Fn",
                            Function      = "Fn",
                            Constructor   = "Co",
                            Field         = "Fd",
                            Variable      = "Vr",
                            Class         = "Cl",
                            Interface     = "If",
                            Module        = "Md",
                            Property      = "Pr",
                            Unit          = "Un",
                            Value         = "Vl",
                            Enum          = "En",
                            Keyword       = "Kw",
                            Snippet       = "<>",
                            Color         = "Co",
                            File          = "Fi",
                            Reference     = "Rf",
                            Folder        = "Fo",
                            EnumMember    = "Em",
                            Constant      = "Cn",
                            Struct        = "St",
                            Event         = "Ev",
                            Operator      = "Op",
                            TypeParameter = "Tp",
                        },
                    }),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-n>"]     = cmp.mapping.select_next_item(),
                    ["<C-p>"]     = cmp.mapping.select_prev_item(),
                    ["<C-y>"]     = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-d>"]     = cmp.mapping.scroll_docs(4),
                    ["<C-u>"]     = cmp.mapping.scroll_docs(-4),
                }),
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                },
            })
        end,
    },

    -- ── Git signs in the gutter (optional polish) ───────────────────────
    {
        "lewis6991/gitsigns.nvim",
        event = "VeryLazy",
        opts = {
            signs = {
                add          = { text = "+" },
                change       = { text = "~" },
                delete       = { text = "_" },
                topdelete    = { text = "-" },
                changedelete = { text = "~" },
            },
        },
    },
})

-- ========================================================================
-- 4. EDITOR SETTINGS (OPTIONS)
-- ========================================================================
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.tabstop        = 4
vim.opt.shiftwidth     = 4
vim.opt.expandtab      = true
vim.opt.clipboard      = "unnamedplus"
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.termguicolors  = true
vim.opt.undofile       = true
vim.opt.signcolumn     = "yes"
vim.opt.scrolloff      = 10
vim.opt.confirm        = true
vim.opt.cursorline     = true       -- highlight current line
vim.opt.showmode       = false      -- lualine already shows the mode
vim.opt.laststatus     = 3          -- single global statusline
vim.opt.pumheight      = 12         -- limit autocomplete popup height

-- Visual whitespace
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function() vim.hl.on_yank() end,
})

-- ========================================================================
-- 5. KEYMAPS
-- ========================================================================
local builtin = require("telescope.builtin")

-- Telescope
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep,  { desc = "Find Grep (Text)" })
vim.keymap.set("n", "<leader>fb", builtin.buffers,    { desc = "Find Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags,  { desc = "Find Help" })

-- Neo-tree
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle Explorer" })

-- Bufferline navigation
vim.keymap.set("n", "<Tab>",   ":BufferLineCycleNext<CR>", { desc = "Next buffer", silent = true })
vim.keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { desc = "Prev buffer", silent = true })
vim.keymap.set("n", "<leader>x", ":bdelete<CR>",           { desc = "Close buffer", silent = true })

-- Hard mode: disable arrow keys
vim.keymap.set("n", "<Left>",  '<cmd>echo "Use h!"<CR>')
vim.keymap.set("n", "<Right>", '<cmd>echo "Use l!"<CR>')
vim.keymap.set("n", "<Up>",    '<cmd>echo "Use k!"<CR>')
vim.keymap.set("n", "<Down>",  '<cmd>echo "Use j!"<CR>')

-- Jump navigation (Zellij-friendly)
vim.keymap.set("n", "<leader>o", "<C-o>", { desc = "Jump Back" })
vim.keymap.set("n", "<leader>i", "<C-i>", { desc = "Jump Forward" })

-- Visual block mode
vim.keymap.set("n", "<leader>v", "<C-v>", { desc = "Visual Block Mode" })

-- Spatial navigation ($ = start, ^ = end)
vim.keymap.set({ "n", "v" }, "$", "^", { desc = "Go to Start (Left)" })
vim.keymap.set({ "n", "v" }, "^", "$", { desc = "Go to End (Right)" })

-- Force relative numbers to stick
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    callback = function()
        if vim.bo.buftype == "" then
            vim.opt_local.number = true
            vim.opt_local.relativenumber = true
        end
    end,
})