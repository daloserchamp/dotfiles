vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = false
local function has_clang_format(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then
    return false
  end
  local found = vim.fs.find({ '.clang-format', '_clang-format' }, { upward = true, path = vim.fs.dirname(name) })
  return #found > 0
end

local function is_big_file(bufnr, max_bytes)
  local ok, stat = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
  return ok and stat ~= nil and stat.size > (max_bytes or 1024 * 1024)
end

local function switch_source_header(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'clangd' })[1]
  if not client then
    return vim.notify('clangd is not attached to this buffer', vim.log.levels.WARN)
  end
  client:request('textDocument/switchSourceHeader', vim.lsp.util.make_text_document_params(bufnr), function(err, result)
    if err then
      return vim.notify(err.message, vim.log.levels.ERROR)
    end
    if not result then
      return vim.notify('No matching header/source file found', vim.log.levels.INFO)
    end
    vim.cmd.edit(vim.uri_to_fname(result))
  end, bufnr)
end
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false

vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250

vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.tabstop = 4
vim.o.shiftwidth = 4

vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 15
vim.o.confirm = true

vim.o.autoread = true

vim.o.sessionoptions = 'buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds'

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal typing mode' })

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader>w', '<cmd>write<CR>', { desc = '[W]rite (save) file' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = '[B]uffer [D]elete' })

-- Move selected lines up/down (stays selected, re-indents)
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Keep the selection after indenting
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left, keep selection' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right, keep selection' })

vim.keymap.set('x', 'p', 'P', { desc = 'Paste without clobbering register' })

vim.keymap.set('i', '<C-v>', function()
  vim.api.nvim_paste(vim.fn.getreg '+', true, -1)
end, { desc = 'paste in insert' })

vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next match (centered)' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous match (centered)' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Reload buffers that changed on disk when coming back to nvim
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  desc = 'Check for external file changes',
  group = vim.api.nvim_create_augroup('user-checktime', { clear = true }),
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd 'checktime'
    end
  end,
})

-- Reopen files
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'reopen',
  group = vim.api.nvim_create_augroup('user-restore-cursor', { clear = true }),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- fix for no name buffers
vim.api.nvim_create_autocmd('BufHidden', {
  desc = 'Wipe leftover empty [No Name] buffers',
  group = vim.api.nvim_create_augroup('user-wipe-empty-buffers', { clear = true }),
  callback = function(ev)
    vim.schedule(function()
      local buf = ev.buf
      if
        vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buftype == ''
        and vim.api.nvim_buf_get_name(buf) == ''
        and not vim.bo[buf].modified
        and vim.fn.bufwinid(buf) == -1
        and vim.api.nvim_buf_line_count(buf) == 1
        and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ''
      then
        pcall(vim.api.nvim_buf_delete, buf, {})
      end
    end)
  end,
})

-- terminal insert
vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'terminal insert',
  group = vim.api.nvim_create_augroup('user-term-insert', { clear = true }),
  pattern = 'term://*',
  callback = function()
    if vim.bo.buftype == 'terminal' and vim.bo.filetype == 'toggleterm' then
      vim.cmd.startinsert()
    end
  end,
})

local indent_widths = {
  javascript = 2,
  javascriptreact = 2,
  typescript = 2,
  typescriptreact = 2,
  html = 2,
  css = 2,
  json = 2,
  haskell = 2,
  cmake = 2,
  java = 4,
}
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Per-language indentation',
  group = vim.api.nvim_create_augroup('user-indent-widths', { clear = true }),
  pattern = vim.tbl_keys(indent_widths),
  callback = function(ev)
    local width = indent_widths[ev.match]
    vim.bo[ev.buf].expandtab = true
    vim.bo[ev.buf].shiftwidth = width
    vim.bo[ev.buf].tabstop = width
    vim.bo[ev.buf].softtabstop = width
  end,
})

vim.api.nvim_create_user_command('Tree', function()
  vim.cmd 'Neotree'
end, {})

vim.api.nvim_create_user_command('FormatToggle', function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify('Format on save: ' .. (vim.g.disable_autoformat and 'OFF' or 'ON'))
end, { desc = 'Toggle format on save' })
vim.keymap.set('n', '<leader>tf', '<cmd>FormatToggle<CR>', { desc = '[T]oggle [F]ormat on save' })

-- ============================================================================
-- Plugin manager
-- ============================================================================
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require('lazy').setup({
  'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically

  { -- Git signs in the gutter + hunk actions
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gs = require 'gitsigns'
        local function gmap(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end
        gmap('n', ']h', function()
          gs.nav_hunk 'next'
        end, 'Next git hunk')
        gmap('n', '[h', function()
          gs.nav_hunk 'prev'
        end, 'Previous git hunk')
        gmap('n', '<leader>hs', gs.stage_hunk, 'git [s]tage hunk')
        gmap('n', '<leader>hr', gs.reset_hunk, 'git [r]eset hunk')
        gmap('v', '<leader>hs', function()
          gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, 'git [s]tage selection')
        gmap('v', '<leader>hr', function()
          gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, 'git [r]eset selection')
        gmap('n', '<leader>hS', gs.stage_buffer, 'git [S]tage buffer')
        gmap('n', '<leader>hp', gs.preview_hunk, 'git [p]review hunk')
        gmap('n', '<leader>hb', function()
          gs.blame_line { full = true }
        end, 'git [b]lame line')
        gmap('n', '<leader>hd', gs.diffthis, 'git [d]iff against index')
        gmap('n', '<leader>tb', gs.toggle_current_line_blame, '[T]oggle git show [b]lame line')
      end,
    },
  },

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        defaults = {
          path_display = { 'filename_first' },
          file_ignore_patterns = { 'node_modules/', '%.git/' },
          borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
        },
        pickers = {
          find_files = { hidden = true },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  -- LSP Plugins
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = { ui = { border = 'single' } } },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      local function tele(picker)
        return function()
          require('telescope.builtin')[picker]()
        end
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grr', tele 'lsp_references', '[G]oto [R]eferences')
          map('gri', tele 'lsp_implementations', '[G]oto [I]mplementation')
          map('grd', tele 'lsp_definitions', '[G]oto [D]efinition')
          map('gd', tele 'lsp_definitions', '[G]oto [D]efinition')
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gO', tele 'lsp_document_symbols', 'Open Document Symbols')
          map('gW', tele 'lsp_dynamic_workspace_symbols', 'Open Workspace Symbols')
          map('grt', tele 'lsp_type_definitions', '[G]oto [T]ype Definition')

          -- source code switcher
          map('<leader>ch', function()
            switch_source_header(event.buf)
          end, '[C]ode: switch [H]eader/source')

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- Highlight other uses of the word under the cursor
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end

          -- Format while typing
          if client and client.name == 'clangd' and vim.lsp.on_type_formatting and has_clang_format(event.buf) then
            vim.lsp.on_type_formatting.enable(true, { client_id = client.id })
          end
        end,
      })

      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'single', source = 'if_many' }, -- [CHANGED] square border
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = { source = 'if_many', spacing = 2 },
      }

      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      local jobs = math.max(2, math.floor(((vim.uv.available_parallelism and vim.uv.available_parallelism()) or 4) / 2))
      vim.lsp.config('clangd', {
        cmd = {
          'clangd',
          '--background-index',
          '--pch-storage=memory',
          '--completion-style=detailed',
          '-j=' .. jobs,
        },
        reuse_client = function(client)
          return client.name == 'clangd'
        end,
      })

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
          },
        },
      })

      vim.lsp.enable {
        'clangd', -- C / C++
        'lua_ls', -- Lua
        'neocmake', -- CMake
        'jdtls', -- Java
        'hls', -- Haskell install via ghcup
        'ts_ls', -- JavaScript / TypeScript / React
        'html', -- HTML
        'cssls', -- CSS
        'emmet_language_server', -- Emmet abbreviations in HTML/CSS/JSX
      }

      require('mason-tool-installer').setup {
        ensure_installed = {
          'clangd',
          'clang-format',
          'codelldb',
          'lua-language-server',
          'stylua',
          'neocmakelsp',
          'jdtls',
          'typescript-language-server',
          'html-lsp',
          'css-lsp',
          'emmet-language-server',
          'prettier',
        },
      }
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = true,
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return nil
        end
        local ft = vim.bo[bufnr].filetype
        local auto_format = {
          lua = true,
          c = true,
          cpp = true,
          javascript = true,
          javascriptreact = true,
          typescript = true,
          typescriptreact = true,
          html = true,
          css = true,
          json = true,
        }
        if not auto_format[ft] then
          return nil
        end
        if (ft == 'c' or ft == 'cpp') and not has_clang_format(bufnr) then
          return nil
        end
        return { timeout_ms = 1500, lsp_format = 'fallback' }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        javascript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescript = { 'prettier' },
        typescriptreact = { 'prettier' },
        html = { 'prettier' },
        css = { 'prettier' },
        json = { 'prettier' },
      },
    },
  },

  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'super-tab',
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        menu = { border = 'single' },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 300,
          window = { border = 'single' },
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'prefer_rust' },
      signature = { enabled = true, window = { border = 'single' } },
    },
  },

  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('gruvbox').setup {
        terminal_colors = true,
      }
      vim.o.background = 'dark'
      vim.cmd.colorscheme 'gruvbox'
    end,
  },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }

      require('mini.surround').setup()

      -- wrap text around visual
      vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true, desc = 'Surround selection' })

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },

  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'cpp',
        'cmake',
        'css',
        'diff',
        'haskell',
        'html',
        'java',
        'javascript',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
        disable = function(_, buf)
          return is_big_file(buf)
        end,
      },
      indent = {
        enable = true,
        disable = function(lang, buf)
          return lang == 'ruby' or lang == 'c' or lang == 'cpp' or is_big_file(buf)
        end,
      },
    },
  },

  {
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {},
  },

  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = { max_lines = 3 },
    keys = {
      { '<leader>tc', '<cmd>TSContext toggle<CR>', desc = '[T]oggle code [C]ontext' },
    },
  },

  {
    'stevearc/aerial.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    cmd = { 'AerialToggle', 'AerialOpen' },
    keys = {
      { '<leader>o', '<cmd>AerialToggle! right<CR>', desc = '[O]utline (symbols)' },
    },
    opts = {
      backends = { 'lsp', 'treesitter' },
      layout = { min_width = 30 },
      float = { border = 'single' },
      nav = { border = 'single' },
    },
  },

  { -- shows available keybindings as you type
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 2000,
      win = { border = 'single' },
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
        },
      },
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>c', group = '[C]ode' },
        { '<leader>b', group = '[B]uffer' },
        { '<leader>d', group = '[D]ebug' },
        { '<leader>S', group = '[S]ession' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },

  {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    lazy = false,
    keys = {
      { '\\', '<cmd>Neotree toggle reveal left<CR>', desc = 'Toggle file tree', silent = true },
      { '|', '<cmd>Neotree toggle buffers left<CR>', desc = 'Toggle open-buffers tree', silent = true },
      { '<leader>bb', '<cmd>Neotree toggle buffers left<CR>', desc = '[B]uffers tree', silent = true },
    },
    opts = {
      popup_border_style = 'single',
      close_if_last_window = true,
      source_selector = {
        winbar = true,
        sources = {
          { source = 'filesystem', display_name = 'Files' },
          { source = 'buffers', display_name = 'Buffers' },
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        window = {
          mappings = {
            ['\\'] = 'close_window',
          },
        },
      },
      buffers = {
        follow_current_file = { enabled = true },
        show_unloaded = true,
        window = {
          mappings = {
            ['\\'] = 'close_window',
            ['d'] = 'buffer_delete',
          },
        },
      },
    },
  },

  {
    'akinsho/toggleterm.nvim',
    version = '*',
    event = 'VeryLazy',
    keys = {
      { '<leader>tt', '<cmd>ToggleTerm<CR>', desc = '[T]oggle [T]erminal' },
    },
    opts = {
      open_mapping = [[<C-\>]],
      direction = 'horizontal',
      size = 15,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_mode = false, -- always start in insert mode
      shade_terminals = false,
      close_on_exit = true,
      float_opts = { border = 'single' },
    },
  },

  {
    'folke/persistence.nvim',
    cond = function()
      return vim.fn.argc(-1) == 0
    end,
    lazy = false,
    opts = {},
    keys = {
      {
        '<leader>Ss',
        function()
          require('persistence').load()
        end,
        desc = '[S]ession: restore for this folder',
      },
      {
        '<leader>Sl',
        function()
          require('persistence').load { last = true }
        end,
        desc = '[S]ession: restore [l]ast one',
      },
      {
        '<leader>Sd',
        function()
          require('persistence').stop()
        end,
        desc = "[S]ession: [d]on't save this one",
      },
    },
    init = function()
      vim.api.nvim_create_autocmd('StdinReadPre', {
        once = true,
        callback = function()
          vim.g.started_with_stdin = true
        end,
      })
      vim.api.nvim_create_autocmd('VimEnter', {
        nested = true,
        callback = function()
          if vim.g.started_with_stdin then
            return
          end
          require('persistence').load()
        end,
      })
    end,
  },

  {
    -- cmake -DCMAKE_BUILD_TYPE=Debug
    'mfussenegger/nvim-dap',
    dependencies = { 'rcarriga/nvim-dap-ui', 'nvim-neotest/nvim-nio' },
    keys = {
      {
        '<F5>',
        function()
          require('dap').continue()
        end,
        desc = 'Debug: start / continue',
      },
      {
        '<F6>',
        function()
          require('dap').pause()
        end,
        desc = 'Debug: pause',
      },
      {
        '<F9>',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Debug: toggle breakpoint',
      },
      {
        '<F10>',
        function()
          require('dap').step_over()
        end,
        desc = 'Debug: step over',
      },
      {
        '<F11>',
        function()
          require('dap').step_into()
        end,
        desc = 'Debug: step into',
      },
      {
        '<S-F11>',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: step out',
      },
      {
        '<S-F5>',
        function()
          require('dap').terminate()
        end,
        desc = 'Debug: stop',
      },

      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Debug: toggle [b]reakpoint',
      },
      {
        '<leader>dB',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: conditional [B]reakpoint',
      },
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = 'Debug: start / [c]ontinue',
      },
      {
        '<leader>dp',
        function()
          require('dap').pause()
        end,
        desc = 'Debug: [p]ause',
      },
      {
        '<leader>do',
        function()
          require('dap').step_over()
        end,
        desc = 'Debug: step [o]ver',
      },
      {
        '<leader>di',
        function()
          require('dap').step_into()
        end,
        desc = 'Debug: step [i]nto',
      },
      {
        '<leader>dO',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: step [O]ut',
      },
      {
        '<leader>dC',
        function()
          require('dap').run_to_cursor()
        end,
        desc = 'Debug: run to [C]ursor',
      },
      {
        '<leader>dk',
        function()
          require('dap').up()
        end,
        desc = 'Debug: stack frame up (caller)',
      },
      {
        '<leader>dj',
        function()
          require('dap').down()
        end,
        desc = 'Debug: stack frame down',
      },
      {
        '<leader>dr',
        function()
          require('dap').restart()
        end,
        desc = 'Debug: [r]estart',
      },
      {
        '<leader>dl',
        function()
          require('dap').run_last()
        end,
        desc = 'Debug: run [l]ast',
      },
      {
        '<leader>dt',
        function()
          require('dap').terminate()
        end,
        desc = 'Debug: [t]erminate',
      },
      {
        '<leader>dx',
        function()
          require('dap').clear_breakpoints()
        end,
        desc = 'Debug: clear all breakpoints',
      },
      {
        '<leader>du',
        function()
          require('dapui').toggle()
        end,
        desc = 'Debug: toggle [u]i',
      },
      {
        '<leader>de',
        function()
          require('dapui').eval()
        end,
        mode = { 'n', 'v' },
        desc = 'Debug: [e]valuate expression',
      },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      dapui.setup {
        layouts = {
          { elements = { 'scopes', 'stacks', 'breakpoints', 'watches' }, size = 40, position = 'left' },
          { elements = { 'repl' }, size = 10, position = 'bottom' },
        },
        icons = { expanded = '▾', collapsed = '▸', current_frame = '▸' },
        controls = {
          icons = vim.g.have_nerd_font and {} or {
            pause = '⏸',
            play = '▶',
            step_into = '⏎',
            step_over = '⏭',
            step_out = '⏮',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏹',
            disconnect = '⏏',
          },
        },
        floating = { border = 'single' },
      }

      local signs = {
        DapBreakpoint = { '●', 'DiagnosticError', '' },
        DapBreakpointCondition = { '◆', 'DiagnosticWarn', '' },
        DapBreakpointRejected = { '○', 'DiagnosticHint', '' },
        DapLogPoint = { '◇', 'DiagnosticInfo', '' },
        DapStopped = { '▶', 'DiagnosticOk', 'Visual' },
      }
      for name, s in pairs(signs) do
        vim.fn.sign_define(name, { text = s[1], texthl = s[2], linehl = s[3], numhl = '' })
      end

      dap.listeners.after.event_initialized['dapui_config'] = function()
        pcall(vim.cmd, 'Neotree close')
        dapui.open()
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
      end

      dap.adapters.codelldb = function(callback)
        local cmd = vim.fn.exepath 'codelldb'
        if cmd == '' then
          cmd = 'codelldb'
        end
        callback {
          type = 'server',
          port = '${port}',
          executable = {
            command = cmd,
            args = { '--port', '${port}' },
            detached = vim.fn.has 'win32' == 0,
          },
        }
      end

      dap.configurations.cpp = {
        {
          name = 'Launch executable',
          type = 'codelldb',
          request = 'launch',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/build/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp
    end,
  },
}, {
  ui = {
    border = 'single',
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
