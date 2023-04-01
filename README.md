# veil.nvim

A blazingly fast, animated, and infinitely customizeable startup / dashboard plugin

> **Warning**  
> Work in progress, there may be some bugs :)

## Features

- [x] Animated sections rendered with virtual text
- [x] Builtin "standard library"
  - [x] Buttons builtin
  - [x] Oldfiles builtin
  - [ ] Current dir builtin
  - [ ] Floating widget builtin
  - [x] Ascii frame anim builtin
  - [x] Vertical padding builtin
- [x] Static text sections
- [x] Dynamic text sections
  - [x] Per-section state
- [ ] Simple and extensible API
  - [ ] Rendering / API V2 (in progress)
- [x] Interactible components (use buttons with `<CR>`)
  - [x] Cursor 'hover' events
  - [x] Lock cursor to menus
- [x] Highlighting
- [x] Shortcut mappings
- [x] Startup in <1ms
- [ ] Mouse events
- [ ] API for advanced rendering / terminal graphics

## Demo (default config)

<!--https://user-images.githubusercontent.com/38540736/227105511-7988cd83-be56-4606-a32d-07d6245d1307.mp4-->
<!--https://user-images.githubusercontent.com/38540736/227207398-b8f7af6a-0e88-4874-93fa-196e78c14938.mp4-->

https://user-images.githubusercontent.com/38540736/228553706-b68e99a7-c4d6-4803-a06e-4e3bb12109ea.mp4

## Installation

<details>
<summary>Using lazy.nvim</summary>

```lua
{
  'willothy/veil.nvim',
  lazy = true,
  dependencies = {
    -- All optional, only required for the default setup.
    -- If you customize your config, these aren't necessary.
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-file-browser.nvim"
  }
  config = true,
  -- or configure with:
  -- opts = { ... }
}
```

</details>

## Configuration

<details>
<summary>Veil comes with the following defaults</summary>
<br/>

The defaults assume you have Telescope installed because... you probably do.<br/>

```lua
local builtin = require("veil.builtin")

local default = {
  sections = {
    builtin.sections.animated(builtin.headers.frames_nvim, {
      hl = { fg = "#5de4c7" },
    }),
    builtin.sections.buttons({
      {
        icon = "",
        text = "Find Files",
        shortcut = "f",
        callback = function()
            require("telescope.builtin").find_files()
        end,
      },
      {
        icon = "",
        text = "Find Word",
        shortcut = "w",
        callback = function()
            require("telescope.builtin").live_grep()
        end,
      },
      {
        icon = "",
        text = "Buffers",
        shortcut = "b",
        callback = function()
            require("telescope.builtin").buffers()
        end,
      },
      {
        icon = "",
        text = "Config",
        shortcut = "c",
        callback = function()
          require("telescope").extensions.file_browser.file_browser({
            path = vim.fn.stdpath("config"),
          })
        end,
      },
    }),
    builtin.sections.oldfiles(),
  },
  mappings = {},
  startup = true,
  listed = false
}

```

</details>

### Configuration Recipes

<details>
<summary>Days of week header by <a href="https://github.com/coopikoop">@coopikoop</a></summary>

```lua
-- in your config:

local current_day = os.date("%A")

require('veil').setup({
  sections = {
    builtin.sections.animated(builtin.headers.frames_days_of_week[current_day], {
      hl = { fg = "#5de4c7" },
    }),
    -- other sections
    -- ...
  }
}

```

</details>
