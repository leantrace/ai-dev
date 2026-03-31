-- Copy this file to projects.lua and customize with your project paths.
-- projects.lua is gitignored.
--
-- Structure: list of windows, each with a name and tabs.
-- Tab types:
--   local:  just cwd + panes
--   docker: cwd + devcontainer { container, workdir, user, shell }
--   ssh:    ssh { host, session } — connects via ssh+tmux (1 pane, tmux handles splits)

local wezterm = require 'wezterm'

return {
  -- Window 1: Local shells
  {
    name = 'Local',
    tabs = {
      {
        name = 'App1',
        cwd = wezterm.home_dir .. '/workspace/app1',
        panes = 3,
      },
      {
        name = 'Scripts',
        cwd = wezterm.home_dir .. '/.local/share/scripts',
        panes = 3,
      },
    },
  },

  -- Window 2: Docker dev containers
  {
    name = 'Docker',
    tabs = {
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
    },
  },

  -- Window 3: SSH + tmux sessions
  {
    name = 'Server',
    tabs = {
      {
        name = 'Main',
        ssh = { host = 'myserver', session = 'main' },
      },
    },
  },
}
