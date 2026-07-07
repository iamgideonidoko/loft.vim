# loft.vim

Native Vim 9+ port of [loft.nvim](https://github.com/iamgideonidoko/loft.nvim).

Loft tracks listed buffers in recency order, lets you mark/pin important ones, cycles through them, reorders them, and shows them in native Vim popup UI.

## Install

Add repo to `runtimepath`, or use any Vim plugin manager.

## Setup

```vim
call loft#Setup({})
```

Default setup runs automatically from `plugin/loft.vim`. Call `loft#Setup()` again to override defaults.

## Commands

- `:LoftToggle`
- `:LoftToggleSmartOrder`
- `:LoftToggleMark`
- `:LoftCloseOthers[!]`
- `:LoftCloseUnmarked[!]`

## Default mappings

- Global:
  - `<leader>lf` open Loft
  - `<Tab>` / `<S-Tab>` next / previous buffer
  - `<leader>x` / `<leader>X` close / force-close current buffer
  - `<leader>ln` / `<leader>lp` next / previous marked buffer
  - `<leader>lm` toggle mark current buffer
  - `<leader>ls` toggle smart order
  - `<leader>la` switch to alternate buffer
  - `<S-M-i>` / `<S-M-o>` move current buffer up / down
- Inside Loft popup:
  - `j` / `k` move cursor
  - `<C-j>` / `<C-k>` move entry
  - `dd` delete entry
  - `D` force-delete entry
  - `m` toggle mark
  - `<CR>` select entry
  - `?` help
  - `<M-j>` / `<M-k>` jump between marked entries
  - `q` / `<Esc>` close
  - `v` / `V` start or clear range selection, then `d` / `D`

## Public API

- `loft#Setup({opts})`
- `loft#actions#*`
- `loft#registry#*`
- `loft#ui#GetBufferMark()`
- `loft#ui#SmartOrderIndicator()`
- `loft#persistence#Save()`
- `loft#persistence#Restore()`

See `:help loft`.

## Compatibility differences

- Vim9 exported autoload functions must start with capital letter. Public Vim API is `loft#Setup()`, `loft#actions#CloseBuffer()`, etc., not Lua-style `require(...)`.
- Vim `:doautocmd User` has no `ev.data`. Loft still fires same `User` events, but payload lives in `g:loft_last_event.data`.
- Vim popup windows have no footer. Smart-order indicator is folded into popup title.
- Multi-line delete inside popup uses native popup range mode (`v`/`V`, then `d`/`D`) instead of true Neovim float visual mode.
- Neovim-only callback keymaps in config are not supported. Vim port supports built-in action names and `false` to disable mappings.
