# lazyscion

[hyperscion](https://github.com/holepunchto/hyperscion)'s `hs ui` in a Neovim float, the way
[lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) opens lazygit. Same reflex: one key,
look at your changes, land, back to the code.

`hs ui` is the lazygit-style terminal UI built into hs:

- **Left:** `[1] Status`, `[2] Files` (what `hs land` would send), `[3] Log` (landed
  changesets), `[4] Review` (what waits on you, and your open asks) and `[5] Tasks` (the
  board: open tasks and who leads each).
- **Right:** the selected file's diff, changeset, ask or task.

| key                   | does                                                         |
| --------------------- | ------------------------------------------------------------ |
| `j` `k`               | move in a list                                               |
| `h` `l`, `tab`, `1-5` | switch panels                                                |
| `enter`, `esc`        | scroll the main panel, and back                              |
| `J` `K`, `ctrl+d/u`   | scroll the main panel from anywhere                          |
| `c` or `P`            | land: asks for a message, then `hs land -m …`                |
| `A`                   | ask for review instead; tab to Reviewers to pick teammates   |
| `p`                   | sync: `hs sync`                                              |
| `d`                   | discard the selected file: `hs restore <path>`               |
| `e`                   | edit the selected file here in Neovim (the float hides)      |
| `a` (in Review)       | approve the selected ask, change or task                     |
| `x` (in Review)       | request changes (asks for a message)                         |
| `m` (in Review)       | comment                                                      |
| `n` (in Tasks)        | file a task: `hs task new <title>`                           |
| `s` / `S` (in Tasks)  | start the selected task / stop (step away from) it           |
| `D` (in Tasks)        | mark it done (asks first)                                    |
| `X` (in Tasks)        | drop a task you filed (asks first)                           |
| `r`                   | refresh                                                      |
| `?`                   | every key                                                    |
| `q`                   | quit                                                         |

## Requirements

- Neovim 0.11 or later.
- `hs` with the `ui` command, on your PATH. Or point `cmd` at a development checkout (below).

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim) (AstroNvim included), add a file such as
`lua/plugins/lazyscion.lua`:

```lua
return {
  "holepunchto/lazyscion", -- or: dir = "~/github/holepunch/lazyscion"
  cmd = "Lazyscion",
  keys = { { "<Leader>gh", "<Cmd>Lazyscion<CR>", desc = "hyperscion UI (lazyscion)" } },
  opts = {},
}
```

In AstroNvim, `<Leader>gg` is lazygit and `<Leader>gh` is free, so the two sit side by side.

## Use

- `:Lazyscion` toggles the float. It looks for the worktree (the nearest `.hs`) from the
  current file, then from the current directory.
- Hiding the float keeps `hs ui` running, so reopening returns to where you were.
- `q` inside it quits `hs ui` and closes the float.
- Buffers reload (`:checktime`) whenever the float hides, so files a sync or a discard
  changed are current.

## Configuration

```lua
require("lazyscion").setup({
  cmd = { "hs" }, -- `ui` is appended
  -- a development checkout: cmd = { "bare", vim.fn.expand("~/github/holepunch/hyperscion/bin.mjs") },
  width = 0.9, -- fraction of the editor
  height = 0.9,
  border = "rounded",
  title = " hyperscion ",
})
```

## How `e` works

Neovim's terminal sets `$NVIM` for the job. `hs ui` sees it and calls back with
`nvim --server $NVIM --remote-expr 'v:lua.require"lazyscion".edit(<path>)'`. That hides the
float and opens the file in the window you came from. Outside Neovim, `hs ui` opens
`$VISUAL` or `$EDITOR` instead.

## License

Apache-2.0
