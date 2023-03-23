# veil.nvim

A dynamic, animated, and infinitely customizeable startup / dashboard plugin

> **Warning**  
> Work in progress

## Features

- [x] Animated sections rendered with virtual text
  - [x] Builtin frames/animation util
- [x] Static text sections
- [x] Dynamic text sections
  - [x] Per-section state
- [x] Sensible API
- [ ] Interactible components
- [ ] Mouse events
- [x] Highlighting
- [ ] Shortcut mappings

## Demo (default config)

https://user-images.githubusercontent.com/38540736/227105511-7988cd83-be56-4606-a32d-07d6245d1307.mp4

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

```lua
{
	---@type Section[]
	sections = {
		require('veil.builtin').animated({
			{ "-- Veil --", "-- Veil --" },
			{ "+- Veil --", "-- Veil -+" },
			{ "++ Veil --", "-- Veil ++" },
			{ "-+ Veil --", "-- Veil -+" },
			{ "-- Veil ++", "++ Veil --" },
			{ "-- Veil -+", "-+ Veil --" },
			{ "++ Veil --", "-- Veil ++" },
			{ "-+ Veil --", "-- Veil -+" },
		}, {
			hl = { fg = "#5de4c7" },
		}),
	},
	startup = true,
}

```

</details>
