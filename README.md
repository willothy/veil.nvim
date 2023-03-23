# veil.nvim

A dynamic, animated, and infinitely customizeable startup / dashboard plugin
 
> Work in progress, there may be some bugs :)

## Features

- [x] Animated sections rendered with virtual text
  - [x] Builtin frames/animation util
- [x] Static text sections
- [x] Dynamic text sections
  - [x] Per-section state
- [x] Simple and extensible API
- [ ] Interactible components (WIP)
- [ ] Mouse events
- [x] Highlighting
- [X] Shortcut mappings

## Demo (default config)

<!--https://user-images.githubusercontent.com/38540736/227105511-7988cd83-be56-4606-a32d-07d6245d1307.mp4-->


https://user-images.githubusercontent.com/38540736/227181889-26249a1d-d6d3-4130-aae5-6891498fed68.mp4


Note: This will be significantly improved once interactive components are in.

## Installation

<details>
<summary>Using lazy.nvim</summary>

```lua
{
    'willothy/veil.nvim',
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
local builtin = require('veil.builtin')

{ 
	sections = {
		-- default anim
		builtin.animated(frames_nvim, {
			hl = { fg = "#5de4c7" },
		}),
		builtin.padding(2),
		builtin.buttons({
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
		builtin.padding(3),
	},
	mappings = {},
	startup = true,
}

```

</details>
