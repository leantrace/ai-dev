local wezterm = require 'wezterm'
local startup = require 'startup'

local config = wezterm.config_builder()

config.window_close_confirmation = 'NeverPrompt'
config.enable_kitty_keyboard = true

-- For example, changing the initial geometry for new windows:
config.initial_cols = 81
config.initial_rows = 22

-- or, changing the font size and color scheme.
config.font_size = 14
config.color_scheme = 'Adventure'

config.keys = {
    {key="Enter", mods="SHIFT", action=wezterm.action.SendString("\n")},
    {key="g", mods="OPT", action=wezterm.action.SendString("@")},
    {key="8", mods="OPT", action=wezterm.action.SendString("{")},
    {key="9", mods="OPT", action=wezterm.action.SendString("}")},
    {key="5", mods="OPT", action=wezterm.action.SendString("[")},
    {key="6", mods="OPT", action=wezterm.action.SendString("]")},
    {key="7", mods="OPT", action=wezterm.action.SendString("|")},
    {key="n", mods="OPT", action=wezterm.action.SendString("~")},
    {key="3", mods="OPT", action=wezterm.action.SendString("#")},
    {key="7", mods="OPT|SHIFT", action=wezterm.action.SendString("\\")}
}

wezterm.on('gui-startup', function(cmd)
  startup.setup_startup_tabs(cmd)
end)

return config