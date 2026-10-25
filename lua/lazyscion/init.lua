-- lazyscion: hyperscion's `hs ui` in a floating terminal, as lazygit.nvim does for lazygit.
-- `hs ui` keeps running while the float is hidden, so reopening returns to where you were.
-- From inside it, `e` on a file calls back into this Neovim (`hs ui` sees $NVIM) through
-- require('lazyscion').edit(path), which hides the float and opens the file.
local M = {}

M.config = {
  -- the hs command; `ui` is appended. For a development checkout:
  --   cmd = { 'bare', vim.fn.expand('~/github/holepunch/hyperscion/bin.mjs') }
  cmd = { 'hs' },
  width = 0.9, -- fraction of the editor
  height = 0.9,
  border = 'rounded',
  title = ' hyperscion ',
}

local state = { buf = nil, win = nil, job = nil, prev = nil }

local function valid_buf()
  return state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf)
end

local function valid_win()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

local function geometry()
  local cols, lines = vim.o.columns, vim.o.lines - vim.o.cmdheight
  local width = math.max(40, math.floor(cols * M.config.width))
  local height = math.max(12, math.floor(lines * M.config.height))
  return {
    relative = 'editor',
    width = math.min(width, cols - 2),
    height = math.min(height, lines - 2),
    col = math.floor((cols - math.min(width, cols - 2)) / 2) - 1,
    row = math.floor((lines - math.min(height, lines - 2)) / 2) - 1,
    style = 'minimal',
    border = M.config.border,
    title = M.config.title,
    title_pos = 'center',
  }
end

-- files `hs sync` or a discard changed while the float was up: reload them
local function reload()
  vim.schedule(function()
    pcall(vim.cmd.checktime)
  end)
end

local function show()
  state.prev = vim.api.nvim_get_current_win()
  state.win = vim.api.nvim_open_win(state.buf, true, geometry())
  vim.wo[state.win].winhighlight = 'NormalFloat:Normal'
end

-- the worktree: the nearest directory holding .hs, from this buffer or from the cwd
local function root()
  return vim.fs.root(0, '.hs') or vim.fs.root(vim.fn.getcwd(), '.hs')
end

function M.open()
  if valid_win() then
    vim.api.nvim_set_current_win(state.win)
    vim.cmd.startinsert()
    return
  end
  if valid_buf() and state.job then
    show()
    vim.cmd.startinsert()
    return
  end

  local dir = root()
  if not dir then
    vim.notify('lazyscion: not inside a hyperscion worktree (no .hs found)', vim.log.levels.WARN)
    return
  end
  local cmd = vim.tbl_map(vim.fn.expand, M.config.cmd)
  if vim.fn.executable(cmd[1]) ~= 1 then
    vim.notify('lazyscion: ' .. cmd[1] .. ' is not on PATH (set cmd in setup())', vim.log.levels.ERROR)
    return
  end
  table.insert(cmd, 'ui')

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = 'hide'
  show()
  state.job = vim.fn.jobstart(cmd, {
    term = true,
    cwd = dir,
    on_exit = function()
      vim.schedule(M.close)
    end,
  })
  vim.bo[state.buf].filetype = 'lazyscion'
  vim.cmd.startinsert()
end

-- hide the float; `hs ui` keeps running
function M.hide()
  if valid_win() then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  if state.prev and vim.api.nvim_win_is_valid(state.prev) then
    vim.api.nvim_set_current_win(state.prev)
  end
  reload()
end

-- `hs ui` exited (q): close the float and drop its buffer
function M.close()
  M.hide()
  if valid_buf() then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.buf, state.job = nil, nil
end

function M.toggle()
  if valid_win() then
    M.hide()
  else
    M.open()
  end
end

-- called by `hs ui` (e on a file) over --remote-expr: returns at once, then hides the float and
-- opens the file in the window you came from
function M.edit(path)
  vim.schedule(function()
    M.hide()
    vim.cmd.edit(vim.fn.fnameescape(path))
  end)
  return ''
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('lazyscion', { clear = true }),
    callback = function()
      if valid_win() then
        vim.api.nvim_win_set_config(state.win, geometry())
      end
    end,
  })
end

return M
