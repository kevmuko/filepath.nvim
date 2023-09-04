# filepath.nvim

Lualine plugin that nicely shows your filepath. Use it conjunction with
`nvim-navic` or `aerial.nvim` in your winbar.

```
local default_options = {
  symbols = {
    default = '',
    modified = '●',
    readonly = '',
    unnamed = '[No Name]',
    separator = '',
  },
  highlights = {
    modified = 'Constant',
    readonly = 'NonText',
    separator = 'NonText',
  },
  path = 'relative',
  filestatus = true,
}
```
