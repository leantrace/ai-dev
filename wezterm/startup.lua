local wezterm = require 'wezterm'
local mux = wezterm.mux

local module = {}

local function docker_exec_args(container, workdir, user, shell)
  user = user or 'ai'
  shell = shell or 'zsh'

  local cmd = string.format(
    'docker exec -it -u %s -w %s %s %s -l',
    user,
    workdir,
    container,
    shell
  )

  return { 'bash', '-lc', cmd }
end

-- panes: 1 = single, 2 = left/right, 3 = left + right + bottom-right
local function create_layout(tab, main_pane, cwd, panes, pane_args)
  panes = panes or 3

  if panes <= 1 then
    main_pane:activate()
    return
  end

  local right_pane = main_pane:split {
    direction = 'Right',
    size = 0.4,
    cwd = cwd,
    args = pane_args,
  }

  if panes == 2 then
    main_pane:activate()
    return
  end

  right_pane:split {
    direction = 'Bottom',
    size = 0.5,
    cwd = cwd,
    args = pane_args,
  }

  main_pane:activate()
end

function module.setup_startup_tabs(cmd)
  -- Load project configs from projects.lua (gitignored)
  local ok, project_configs = pcall(require, 'projects')
  if not ok then
    wezterm.log_error('projects.lua not found — create it from projects.example.lua')
    project_configs = {
      { name = 'Default', cwd = wezterm.home_dir, panes = 1 },
    }
  end

  local window = nil

  for i, config in ipairs(project_configs) do
    local tab, main_pane, current_window
    local panes = config.panes or 3

    local pane_args = nil
    if config.devcontainer then
      pane_args = docker_exec_args(
        config.devcontainer.container,
        config.devcontainer.workdir,
        config.devcontainer.user,
        config.devcontainer.shell
      )
    end

    local spawn = { cwd = config.cwd }

    if i == 1 and cmd and cmd.args and #cmd.args > 0 then
      spawn.args = cmd.args
    elseif pane_args then
      spawn.args = pane_args
    end

    if i == 1 then
      tab, main_pane, current_window = mux.spawn_window(spawn)
      window = current_window
    else
      tab, main_pane = window:spawn_tab(spawn)
    end

    tab:set_title(config.name)

    create_layout(tab, main_pane, config.cwd, panes, pane_args)
  end

  if window then
    window:gui_window():focus()
    local tabs = window:tabs()
    if tabs[1] then
      tabs[1]:activate()
    end
  end
end

return module
