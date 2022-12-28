# Clover

A neovim plugin to highlight test coverage inline.

See `:h nvim-clover` for full documentation. Requires neovim >= 0.8.1.

## Installation

Clover can be installed with any plugin manager and needs no special
configuration.

With [lazy.nvim](folke/lazy.nvim):

```lua
require("lazy").setup({
  "rliebz/nvim-clover"
})
```

With [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use("rliebz/nvim-clover")
```

## Language/Tool Support

Clover aims to be a generic coverage tool, but has limited language and tooling
support. Feel free to open a pull request or issue as needed.

| Runner  | Requirements            | Languages                        |
| ------- | ----------------------- | -------------------------------- |
| Go Test | `go`                    | Go                               |
| Jest    | `npx`, `jest`           | Javascript, JSX, Typescript, TSX |
| Pytest  | `pytest`, `coverage.py` | Python                           |

Configuration from [vim-test](https://github.com/vim-test/vim-test) is read and
attempted to be used if configured.
