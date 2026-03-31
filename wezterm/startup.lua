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

local function ssh_tmux_args(host, session, workdir)
  session = session or 'main'
  local tmux_cmd = 'tmux new-session -A -s ' .. session
  if workdir then
    tmux_cmd = tmux_cmd .. ' -c ' .. workdir
  end
  local cmd = string.format('ssh %s -t "%s"', host, tmux_cmd)
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

local function get_pane_args(config)
  if config.devcontainer then
    return docker_exec_args(
      config.devcontainer.container,
      config.devcontainer.workdir,
      config.devcontainer.user,
      config.devcontainer.shell
    )
  elseif config.ssh then
    return ssh_tmux_args(config.ssh.host, config.ssh.session, config.ssh.workdir)
  end
  return nil
end

local function spawn_window_group(window_config, is_first_window, cmd)
  local tabs = window_config.tabs or {}
  local window = nil

  for i, config in ipairs(tabs) do
    local tab, main_pane, current_window
    local panes = config.panes or 3
    local pane_args = get_pane_args(config)

    local spawn = { cwd = config.cwd or wezterm.home_dir }

    if is_first_window and i == 1 and cmd and cmd.args and #cmd.args > 0 then
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

    -- For SSH tabs, only 1 pane (tmux handles splits)
    if config.ssh then
      panes = 1
    end

    create_layout(tab, main_pane, config.cwd or wezterm.home_dir, panes, pane_args)
  end

  return window
end

function module.setup_startup_tabs(cmd)
  -- Load project configs from projects.lua (gitignored)
  local ok, windows = pcall(require, 'projects')
  if not ok then
    wezterm.log_error('projects.lua not found — create it from projects.example.lua')
    windows = {
      {
        name = 'Default',
        tabs = {
          { name = 'Home', cwd = wezterm.home_dir, panes = 1 },
        },
      },
    }
  end

  -- Check WEZTERM_WINDOW_GROUP env var to selectively launch window groups.
  -- Comma-separated list of window names, e.g. "Local,Server"
  -- If unset, all windows are launched.
  local filter = os.getenv('WEZTERM_WINDOW_GROUP')
  local allowed = nil
  if filter then
    allowed = {}
    for name in string.gmatch(filter, '([^,]+)') do
      allowed[name:match('^%s*(.-)%s*$')] = true
    end
  end

  local first_window = nil

  for i, window_config in ipairs(windows) do
    if not allowed or allowed[window_config.name] then
      local is_first = first_window == nil
      local window = spawn_window_group(window_config, is_first, cmd)
      if is_first then
        first_window = window
      end
    end
  end

  if first_window then
    first_window:gui_window():focus()
    local tabs = first_window:tabs()
    if tabs[1] then
      tabs[1]:activate()
    end
  end
end

return module
