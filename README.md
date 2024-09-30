# mark-signs.nvim

## Features

- View marks in the sign column.

## Installation

Use your favorite plugin manager. For example, using lazy.nvim you would add
the following line to the `spec` field of setup:

```Lua
{
  "insanum/mark-signs.nvim",
  event = "VeryLazy",
  opts = {},
}
```

## Setup

```lua
require('mark-signs').setup({
  -- Which builtin marks to show. default = {}
  builtin_marks = { ".", "<", ">", "^" },

  -- How often (in ms) to redraw signs and recompute mark positions. Higher
  -- values will have better performance but may cause visual lag. Lower
  -- lower values may cause performance penalties. default = 150
  refresh_interval = 250,

  -- Sign priorities for each type of mark (lowercase/uppercase/builtin). Can
  -- be either a table with all/none of the keys, or a single number in which
  -- case the priority applies to all marks. default = 10
  sign_priority = { lower=10, upper=15, builtin=8 },

  -- Override the default key mappings.
  mappings = {}
})
```

See `:help mark-signs` for the configuration that can be passed to the setup
function.

## Mappings

The following default mappings are included:

```
    mx              Set mark x
    dmx             Delete mark x
```

You can change the keybindings by setting the `mapping` table in the setup
function:

```lua
require('mark-signs').setup({
  mappings = {
    set = "n",
    delete = "dn"
  }
})
```

The following keys are available to be passed to the mapping table:

```
  set                    Sets a letter mark (will wait for mark input).
  delete                 Delete a letter mark (will wait for mark input).
```

mark-signs.nvim also provides a list of `<Plug>` mappings allowing you to
map commands via vimscript. The provided mappings are:

```
<Plug>(Mark-signs-set)
<Plug>(Mark-signs-delete)
```

## Highlights and Commands

mark-signs.nvim defines the following highlight groups:

`MarkSignsHL` The highlight group for displayed mark signs.

`MarkSignsNumHL` The highlight group for the number line in a signcolumn.

## Appreciation

This plugin is a copy and refactor of the much more feature rich
[marks.nvim](https://github.com/chentoast/marks.nvim) plugin.

