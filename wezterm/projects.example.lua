-- Copy this file to projects.lua and customize with your project paths.
-- projects.lua is gitignored.

local wezterm = require 'wezterm'

return {
  {
    name = 'App1',
    cwd = wezterm.home_dir .. '/workspace/app1',
    panes = 3,
    devcontainer = {
      container = 'ai-dev',
      workdir = '/home/ai/workspace/app1',
      user = 'ai',
      shell = 'zsh',
    },
  },
  {
    name = 'App2',
    cwd = wezterm.home_dir .. '/workspace/app2',
    panes = 3,
    devcontainer = {
      container = 'ai-dev',
      workdir = '/home/ai/workspace/app2',
      user = 'ai',
      shell = 'zsh',
    },
  },
  {
    name = 'Local',
    cwd = wezterm.home_dir .. '/workspace',
    panes = 1,
  },
}
