# veil.nvim

A blazingly fast, animated, and infinitely customizeable startup / dashboard plugin

> **Warning**    
> Work in progress, there may be some bugs :)

## Features

- [x] Animated sections rendered with virtual text
- [x] Builtin "standard library"
  - [x] Buttons builtin
  - [x] Ascii frame anim builtin
  - [x] Vertical padding builtin
- [x] Static text sections
- [x] Dynamic text sections
  - [x] Per-section state
- [x] Simple and extensible API
- [x] Interactible components (use buttons with `<CR>`)
  - [ ] Cursor 'hover' events
  - [ ] Lock cursor to menus
- [x] Highlighting
- [x] Shortcut mappings
- [x] Startup in <1ms
- [ ] Mouse events
- [ ] API for advanced rendering / terminal graphics
  - [ ] Bundle drawille (temporary, in progress)
  - [ ] Custom rendering API (to eventually replace drawille dependency)

## Demo (default config)

<!--https://user-images.githubusercontent.com/38540736/227105511-7988cd83-be56-4606-a32d-07d6245d1307.mp4-->

https://user-images.githubusercontent.com/38540736/227207398-b8f7af6a-0e88-4874-93fa-196e78c14938.mp4

## Installation

<details>
<summary>Using lazy.nvim</summary>

```lua
{
    'willothy/veil.nvim',
    config = true,
    lazy = true,
    event = 'VimEnter',
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
		builtin.sections.padding(2),
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
		builtin.sections.padding(3),
	},
	mappings = {},
	startup = true,
}

```

</details>
