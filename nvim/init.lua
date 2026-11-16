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

local function reindent(first, last, force)
  if first == nil or last == nil or (last <= first and not force) then
    return
  end
  if not vim.bo.modifiable then
    return
  end
  if vim.bo.indentexpr == '' and not vim.bo.cindent then
    return
  end
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local before = #(vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1] or '')
  pcall(vim.cmd.undojoin)
  vim.cmd(('silent keepjumps %d,%dnormal! =='):format(first, last))
  local after = #(vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1] or '')
  pcall(vim.api.nvim_win_set_cursor, win, { cursor[1], math.max(0, cursor[2] + after - before) })
end

local function put_and_reindent(cmd)
  return function()
    local reg = vim.v.register
    local linewise = vim.fn.getregtype(reg):sub(1, 1) == 'V'
    vim.cmd(('normal! %d"%s%s'):format(vim.v.count1, reg, cmd))
    local first = vim.api.nvim_buf_get_mark(0, '[')[1]
    local last = vim.api.nvim_buf_get_mark(0, ']')[1]
    reindent(first, last, linewise)
  end
end

local paste_start
vim.paste = (function(original)
  return function(lines, phase)
    if phase == -1 or phase == 1 then
      paste_start = vim.api.nvim_win_get_cursor(0)[1]
    end
    local result = original(lines, phase)
    if (phase == -1 or phase == 3) and vim.fn.mode() ~= 'c' and vim.bo.buftype == '' then
      reindent(paste_start, vim.api.nvim_win_get_cursor(0)[1])
    end
    return result
  end
end)(vim.paste)

local function block_comment_markers()
  local open, close
  for part in vim.gsplit(vim.bo.comments, ',', { plain = true }) do
    local flags, text = part:match '^([^:]*):(.*)$'
    if flags and text and text ~= '' then
      if flags:find('s', 1, true) then
        open = text
      end
      if flags:find('e', 1, true) then
        close = text
      end
    end
  end
  if open and close then
    return open, close
  end
end

local function toggle_block_comment()
  local open, close = block_comment_markers()
  if not open then
    vim.api.nvim_feedkeys('gc', 'mx', false)
    return
  end
  local mode = vim.fn.mode()
  local a = vim.fn.getpos 'v'
  local b = vim.fn.getpos '.'
  local srow, scol, erow, ecol = a[2], a[3], b[2], b[3]
  if srow > erow or (srow == erow and scol > ecol) then
    srow, scol, erow, ecol = erow, ecol, srow, scol
  end
  vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
  local first = vim.api.nvim_buf_get_lines(0, srow - 1, srow, false)[1]
  local last = vim.api.nvim_buf_get_lines(0, erow - 1, erow, false)[1]
  local scol0, ecol0
  if mode == 'V' then
    scol0 = (first:find '%S' or 1) - 1
    ecol0 = #last
  else
    scol0 = math.min(scol - 1, #first)
    local clamped = math.min(ecol, #last)
    ecol0 = clamped < 1 and 0 or clamped + vim.str_utf_end(last, clamped)
  end
  local text = vim.api.nvim_buf_get_text(0, srow - 1, scol0, erow - 1, ecol0, {})
  local head = text[1]
  local tail = text[#text]
  local long_enough = #text > 1 or #head >= #open + #close
  if long_enough and head:sub(1, #open) == open and tail:sub(-#close) == close then
    local trailing = tail:match('%s?' .. vim.pesc(close) .. '$')
    local leading = head:match('^' .. vim.pesc(open) .. '%s?')
    vim.api.nvim_buf_set_text(0, erow - 1, ecol0 - #trailing, erow - 1, ecol0, {})
    vim.api.nvim_buf_set_text(0, srow - 1, scol0, srow - 1, scol0 + #leading, {})
  else
    vim.api.nvim_buf_set_text(0, erow - 1, ecol0, erow - 1, ecol0, { ' ' .. close })
    vim.api.nvim_buf_set_text(0, srow - 1, scol0, srow - 1, scol0, { open .. ' ' })
  end
end

local function wrap_diagnostic(diagnostic)
  local win = vim.api.nvim_get_current_win()
  local textoff = vim.fn.getwininfo(win)[1].textoff
  local width = math.max(30, vim.api.nvim_win_get_width(win) - textoff - (diagnostic.col or 0) - 5)
  local out = {}
  for _, paragraph in ipairs(vim.split(diagnostic.message, '\n', { plain = true })) do
    local line = ''
    for word in paragraph:gmatch '%S+' do
      if line == '' then
        line = word
      elseif #line + 1 + #word <= width then
        line = line .. ' ' .. word
      else
        table.insert(out, line)
        line = word
      end
    end
    table.insert(out, line)
  end
  return table.concat(out, '\n')
end

vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false

vim.o.clipboard = 'unnamedplus'

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
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic under cursor' })
vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, { desc = '[C]ode [A]ction (diagnostic fixes)' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal typing mode' })

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader>w', '<cmd>write<CR>', { desc = '[W]rite (save) file' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = '[B]uffer [D]elete' })

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

vim.keymap.set('v', '<', '<gv', { desc = 'Indent left, keep selection' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right, keep selection' })

for _, key in ipairs { 'd', 'D', 'x', 'X', 'c', 'C', 's', 'S' } do
  vim.keymap.set('n', key, '"d' .. key, { desc = 'Delete into register d' })
end
for _, key in ipairs { 'd', 'D', 'x', 'X', 'c', 'C', 's' } do
  vim.keymap.set('x', key, '"d' .. key, { desc = 'Delete into register d' })
end

vim.keymap.set('n', 'p', put_and_reindent 'p', { desc = 'Paste and re-indent' })
vim.keymap.set('n', 'P', put_and_reindent 'P', { desc = 'Paste before and re-indent' })
vim.keymap.set('x', 'p', function()
  local reg = vim.v.register
  local linewise = vim.fn.getregtype(reg):sub(1, 1) == 'V'
  vim.cmd 'normal! "dygvP'
  local first = vim.api.nvim_buf_get_mark(0, '[')[1]
  local last = vim.api.nvim_buf_get_mark(0, ']')[1]
  reindent(first, last, linewise)
end, { desc = 'Paste over selection (old text goes to register d)' })

vim.keymap.set('i', '<C-v>', function()
  vim.api.nvim_paste(vim.fn.getreg '+', true, -1)
end, { desc = 'paste in insert' })

vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next match (centered)' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous match (centered)' })

vim.keymap.set('n', '<leader>cc', 'gcc', { remap = true, desc = '[C]ode: toggle line [c]omment' })
vim.keymap.set('x', '<leader>cc', toggle_block_comment, { desc = '[C]ode: toggle block [c]omment on selection' })
vim.keymap.set('x', '<leader>cl', 'gc', { remap = true, desc = '[C]ode: toggle [l]ine comments on selection' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  desc = 'Check for external file changes',
  group = vim.api.nvim_create_augroup('user-checktime', { clear = true }),
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd 'checktime'
    end
  end,
})

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

local buffer_panel = { buf = nil, win = nil, map = {}, current = nil, width = 32 }

local function panel_win_valid()
  return buffer_panel.win ~= nil and vim.api.nvim_win_is_valid(buffer_panel.win)
end

local function panel_buf_valid()
  return buffer_panel.buf ~= nil and vim.api.nvim_buf_is_valid(buffer_panel.buf)
end

local function is_file_buffer(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == '' and vim.api.nvim_buf_get_name(buf) ~= ''
end

local function panel_refresh()
  if not panel_buf_valid() then
    return
  end
  local entries, counts = {}, {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_file_buffer(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      local base = vim.fs.basename(name)
      counts[base] = (counts[base] or 0) + 1
      table.insert(entries, { buf = buf, name = name, base = base })
    end
  end
  local lines, map, current_line = {}, {}, nil
  for i, entry in ipairs(entries) do
    local label = entry.base
    if counts[entry.base] > 1 then
      label = label .. ' (' .. vim.fs.basename(vim.fs.dirname(entry.name)) .. ')'
    end
    if vim.bo[entry.buf].modified then
      label = label .. ' +'
    end
    lines[i] = ' ' .. label
    map[i] = entry.buf
    if entry.buf == buffer_panel.current then
      current_line = i
    end
  end
  if #lines == 0 then
    lines = { ' (no open files)' }
  end
  buffer_panel.map = map
  local focused = panel_win_valid() and vim.api.nvim_get_current_win() == buffer_panel.win
  local row = focused and vim.api.nvim_win_get_cursor(buffer_panel.win)[1] or nil
  vim.bo[buffer_panel.buf].modifiable = true
  vim.api.nvim_buf_set_lines(buffer_panel.buf, 0, -1, false, lines)
  vim.bo[buffer_panel.buf].modifiable = false
  if panel_win_valid() then
    if focused then
      pcall(vim.api.nvim_win_set_cursor, buffer_panel.win, { math.min(row, #lines), 0 })
    elseif current_line then
      pcall(vim.api.nvim_win_set_cursor, buffer_panel.win, { current_line, 0 })
    end
  end
end

local function close_panel()
  if panel_win_valid() then
    pcall(vim.api.nvim_win_close, buffer_panel.win, true)
  end
  buffer_panel.win = nil
end

local function target_window()
  local function usable(win)
    if not vim.api.nvim_win_is_valid(win) or win == buffer_panel.win then
      return false
    end
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.bo[buf].buftype == '' and vim.api.nvim_win_get_config(win).relative == ''
  end
  local previous = vim.fn.win_getid(vim.fn.winnr '#')
  if usable(previous) then
    return previous
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if usable(win) then
      return win
    end
  end
  vim.cmd 'botright vsplit'
  return vim.api.nvim_get_current_win()
end

local function open_panel()
  pcall(vim.cmd, 'Neotree close')
  if panel_win_valid() then
    vim.api.nvim_set_current_win(buffer_panel.win)
    return
  end
  local current = vim.api.nvim_get_current_buf()
  if is_file_buffer(current) then
    buffer_panel.current = current
  end
  if not panel_buf_valid() then
    local buf = vim.api.nvim_create_buf(false, true)
    buffer_panel.buf = buf
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = 'bufferpanel'
    vim.bo[buf].modifiable = false
    local function selected()
      return buffer_panel.map[vim.api.nvim_win_get_cursor(0)[1]]
    end
    vim.keymap.set('n', '<CR>', function()
      local target = selected()
      if not target then
        return
      end
      vim.api.nvim_set_current_win(target_window())
      vim.cmd.buffer(target)
    end, { buffer = buf, desc = 'Open file' })
    vim.keymap.set('n', 'd', function()
      local target = selected()
      if not target then
        return
      end
      local ok, err = pcall(vim.cmd, 'bdelete ' .. target)
      if not ok then
        vim.notify(tostring(err), vim.log.levels.WARN)
      end
      vim.schedule(panel_refresh)
    end, { buffer = buf, desc = 'Close file buffer' })
    vim.keymap.set('n', 'q', close_panel, { buffer = buf, desc = 'Close panel' })
  end
  vim.cmd('topleft ' .. buffer_panel.width .. 'vsplit')
  local win = vim.api.nvim_get_current_win()
  buffer_panel.win = win
  vim.api.nvim_win_set_buf(win, buffer_panel.buf)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].cursorline = true
  vim.wo[win].winfixwidth = true
  vim.wo[win].wrap = false
  vim.wo[win].list = false
  vim.wo[win].spell = false
  panel_refresh()
end

local function panel_focus_or_close()
  if panel_win_valid() and vim.api.nvim_get_current_win() == buffer_panel.win then
    close_panel()
  else
    open_panel()
  end
end

local function neotree_focus_or_close()
  if vim.bo.filetype == 'neo-tree' then
    vim.cmd 'Neotree close'
  else
    close_panel()
    vim.cmd 'Neotree focus filesystem left reveal'
  end
end

local function terminal_focus_or_close()
  if vim.bo.filetype == 'toggleterm' then
    vim.cmd 'ToggleTerm'
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'toggleterm' then
      vim.api.nvim_set_current_win(win)
      vim.cmd.startinsert()
      return
    end
  end
  vim.cmd 'ToggleTerm'
end

vim.keymap.set('n', '\\', neotree_focus_or_close, { desc = 'Focus or close file tree' })
vim.keymap.set('n', '|', panel_focus_or_close, { desc = 'Focus or close open-files panel' })
vim.keymap.set('n', '<leader>bb', panel_focus_or_close, { desc = '[B]uffers panel' })
vim.keymap.set({ 'n', 'i', 't' }, '<C-\\>', terminal_focus_or_close, { desc = 'Focus or close terminal' })

local panel_group = vim.api.nvim_create_augroup('user-buffer-panel', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufAdd', 'BufDelete', 'BufWipeout', 'BufFilePost', 'BufModifiedSet', 'BufWritePost' }, {
  group = panel_group,
  callback = function(ev)
    if is_file_buffer(ev.buf) and vim.api.nvim_get_current_buf() == ev.buf then
      buffer_panel.current = ev.buf
    end
    vim.schedule(panel_refresh)
  end,
})
vim.api.nvim_create_autocmd('WinEnter', {
  group = panel_group,
  callback = function()
    if panel_win_valid() and vim.api.nvim_get_current_win() == buffer_panel.win and #vim.api.nvim_tabpage_list_wins(0) == 1 then
      vim.schedule(function()
        pcall(vim.cmd, 'quit')
      end)
    end
  end,
})

local function in_arguments()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok then
    return false
  end
  local argument_nodes = { argument_list = true, arguments = true, parameter_list = true, parameters = true, formal_parameters = true }
  local body_nodes = { compound_statement = true, statement_block = true, block = true, function_body = true }
  while node do
    local node_type = node:type()
    if argument_nodes[node_type] then
      return true
    end
    if body_nodes[node_type] then
      return false
    end
    node = node:parent()
  end
  return false
end

local hover_timer = vim.uv.new_timer()
vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, {
  desc = 'Show hover or signature help after the cursor rests',
  group = vim.api.nvim_create_augroup('user-idle-hover', { clear = true }),
  callback = function()
    hover_timer:stop()
    if vim.fn.mode() ~= 'n' then
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    if #vim.lsp.get_clients { bufnr = buf } == 0 then
      return
    end
    hover_timer:start(
      3000,
      0,
      vim.schedule_wrap(function()
        if vim.fn.mode() ~= 'n' or vim.api.nvim_get_current_buf() ~= buf then
          return
        end
        local opts = { silent = true, focus = false, border = 'single' }
        if in_arguments() then
          vim.lsp.buf.signature_help(opts)
        else
          vim.lsp.buf.hover(opts)
        end
      end)
    )
  end,
})

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require('lazy').setup({
  'NMAC427/guess-indent.nvim',

  {
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

  {
    'akinsho/git-conflict.nvim',
    version = '*',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = { default_mappings = false },
    keys = {
      { '<leader>mo', '<cmd>GitConflictChooseOurs<CR>', desc = '[M]erge: keep [o]urs' },
      { '<leader>mt', '<cmd>GitConflictChooseTheirs<CR>', desc = '[M]erge: keep [t]heirs' },
      { '<leader>mb', '<cmd>GitConflictChooseBoth<CR>', desc = '[M]erge: keep [b]oth' },
      { '<leader>mn', '<cmd>GitConflictChooseNone<CR>', desc = '[M]erge: keep [n]either' },
      { '<leader>ml', '<cmd>GitConflictListQf<CR>', desc = '[M]erge: [l]ist conflicts' },
      { ']x', '<cmd>GitConflictNextConflict<CR>', desc = 'Next merge conflict' },
      { '[x', '<cmd>GitConflictPrevConflict<CR>', desc = 'Previous merge conflict' },
    },
  },

  {
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

          map('<leader>ch', function()
            switch_source_header(event.buf)
          end, '[C]ode: switch [H]eader/source')

          local client = vim.lsp.get_client_by_id(event.data.client_id)

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

          if client and client.name == 'clangd' and vim.lsp.on_type_formatting and has_clang_format(event.buf) then
            vim.lsp.on_type_formatting.enable(true, { client_id = client.id })
          end
        end,
      })

      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'single', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = { source = 'if_many', spacing = 2, current_line = false },
        virtual_lines = { current_line = true, format = wrap_diagnostic },
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
          '--function-arg-placeholders=false',
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
        'clangd',
        'lua_ls',
        'neocmake',
        'jdtls',
        'hls',
        'ts_ls',
        'html',
        'cssls',
        'emmet_language_server',
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

  {
    'smjonas/inc-rename.nvim',
    cmd = 'IncRename',
    keys = {
      {
        '<F2>',
        function()
          return ':IncRename ' .. vim.fn.expand '<cword>'
        end,
        expr = true,
        desc = 'Rename symbol (project-wide, with preview)',
      },
    },
    opts = {},
  },

  {
    'Badhi/nvim-treesitter-cpp-tools',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = { 'c', 'cpp' },
    config = function()
      local source_extensions = { cpp = true, cc = true, cxx = true, ['c++'] = true, C = true }
      local ignored_dirs = { ['.git'] = true, ['node_modules'] = true, ['.cache'] = true, ['CMakeFiles'] = true, ['build'] = true }

      local function split_name(path)
        return vim.fs.basename(path):match '^(.*)%.([^.]+)$'
      end

      local function closeness(path, header)
        local a = vim.split(vim.fs.dirname(path), '/', { plain = true })
        local b = vim.split(vim.fs.dirname(header), '/', { plain = true })
        local shared = 0
        for i = 1, math.min(#a, #b) do
          if a[i] ~= b[i] then
            break
          end
          shared = shared + 1
        end
        return shared
      end

      local function pick_closest(paths, header)
        local best, best_score
        for _, path in ipairs(paths) do
          local score = closeness(path, header)
          if not best or score > best_score then
            best, best_score = path, score
          end
        end
        return best
      end

      local function find_source(header)
        local stem = split_name(header)
        local function matches(path)
          local name, ext = split_name(path)
          return name ~= nil and name == stem and source_extensions[ext] == true
        end
        local from_buffers = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local name = vim.api.nvim_buf_get_name(buf)
          if name ~= '' and vim.bo[buf].buftype == '' and matches(name) then
            table.insert(from_buffers, vim.fs.normalize(name))
          end
        end
        if #from_buffers > 0 then
          return pick_closest(from_buffers, header)
        end
        local cwd = vim.fn.getcwd()
        local from_disk = {}
        local walker = vim.fs.dir(cwd, {
          depth = 25,
          skip = function(dir)
            return not ignored_dirs[dir]
          end,
        })
        for name, kind in walker do
          if kind == 'file' and matches(name) then
            table.insert(from_disk, vim.fs.normalize(vim.fs.joinpath(cwd, name)))
          end
        end
        return pick_closest(from_disk, header)
      end

      local function write_to_source(str)
        local header = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
        local source = find_source(header)
        if not source then
          vim.notify('No matching source file found for ' .. vim.fs.basename(header), vim.log.levels.WARN)
          return
        end
        local buf = vim.fn.bufadd(source)
        vim.fn.bufload(buf)
        if not vim.bo[buf].modifiable then
          vim.notify(vim.fs.basename(source) .. ' is not modifiable', vim.log.levels.WARN)
          return
        end
        local text = (str:gsub('^\n+', ''):gsub('\n+$', ''))
        local lines = vim.split(text, '\n', { plain = true })
        local count = vim.api.nvim_buf_line_count(buf)
        local tail = vim.api.nvim_buf_get_lines(buf, count - 1, count, false)[1]
        if count == 1 and tail == '' then
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        else
          if tail ~= '' then
            table.insert(lines, 1, '')
          end
          vim.api.nvim_buf_set_lines(buf, count, count, false, lines)
        end
        vim.notify('Added definitions to ' .. vim.fn.fnamemodify(source, ':.') .. ' (unsaved)')
      end

      require('nt-cpp-tools').setup {
        preview = { quit = 'q', accept = '<tab>' },
        custom_define_class_function_commands = {
          TSCppImplWrite = { output_handle = write_to_source },
        },
      }
      vim.keymap.set('n', '<leader>ci', '<cmd>TSCppImplWrite<CR>', { desc = '[C]ode: [I]mplement member function in source file' })
      vim.keymap.set('x', '<leader>ci', ':TSCppImplWrite<CR>', { desc = '[C]ode: [I]mplement selected member functions in source file' })
    end,
  },

  {
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

  {
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
          lsp = {
            transform_items = function(_, items)
              local kinds = vim.lsp.protocol.CompletionItemKind
              local snippet = vim.lsp.protocol.InsertTextFormat.Snippet
              local function strip(text)
                if type(text) == 'string' and text:find('${', 1, true) then
                  return (text:gsub('%b()', '($0)', 1))
                end
                return text
              end
              for _, item in ipairs(items) do
                local callable = item.kind == kinds.Function or item.kind == kinds.Method or item.kind == kinds.Constructor
                if callable and item.insertTextFormat == snippet then
                  item.insertText = strip(item.insertText)
                  if item.textEdit then
                    item.textEdit.newText = strip(item.textEdit.newText)
                  end
                end
              end
              return items
            end,
          },
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
      require('gruvbox').setup {
        terminal_colors = true,
      }
      vim.o.background = 'dark'
      vim.cmd.colorscheme 'gruvbox'
    end,
  },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }

      require('mini.surround').setup()

      vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true, desc = 'Surround selection' })

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
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
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)
      require 'nvim-treesitter.query_predicates'
      local query = vim.treesitter.query
      local function capture_node(match, id)
        local node = match[id]
        if type(node) == 'table' then
          return node[#node]
        end
        return node
      end
      local mimetype_languages = {
        ['importmap'] = 'json',
        ['module'] = 'javascript',
        ['application/ecmascript'] = 'javascript',
        ['text/ecmascript'] = 'javascript',
      }
      local info_string_aliases = { ex = 'elixir', pl = 'perl', sh = 'bash', uxn = 'uxntal', ts = 'typescript' }
      query.add_directive('set-lang-from-mimetype!', function(match, _, bufnr, pred, metadata)
        local node = capture_node(match, pred[2])
        if not node then
          return
        end
        local value = vim.treesitter.get_node_text(node, bufnr)
        local language = mimetype_languages[value]
        if language then
          metadata['injection.language'] = language
        else
          local parts = vim.split(value, '/', {})
          metadata['injection.language'] = parts[#parts]
        end
      end, { force = true, all = true })
      query.add_directive('set-lang-from-info-string!', function(match, _, bufnr, pred, metadata)
        local node = capture_node(match, pred[2])
        if not node then
          return
        end
        local alias = vim.treesitter.get_node_text(node, bufnr):lower()
        local filetype = vim.filetype.match { filename = 'a.' .. alias }
        metadata['injection.language'] = filetype or info_string_aliases[alias] or alias
      end, { force = true, all = true })
      query.add_directive('downcase!', function(match, _, bufnr, pred, metadata)
        local id = pred[2]
        local node = capture_node(match, id)
        if not node then
          return
        end
        local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ''
        metadata[id] = metadata[id] or {}
        metadata[id].text = string.lower(text)
      end, { force = true, all = true })
    end,
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

  {
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
        { '<leader>m', group = '[M]erge conflict' },
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
    opts = {
      popup_border_style = 'single',
      close_if_last_window = true,
      window = {
        mappings = {
          ['<'] = 'none',
          ['>'] = 'none',
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
      },
    },
  },

  {
    'akinsho/toggleterm.nvim',
    version = '*',
    event = 'VeryLazy',
    keys = {
      { '<leader>tt', terminal_focus_or_close, desc = '[T]oggle [T]erminal (focus or close)' },
    },
    opts = {
      direction = 'horizontal',
      size = 15,
      start_in_insert = true,
      persist_mode = false,
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
        close_panel()
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
