import std/[tables]

import selector, project, tmuxutils

# TODO: add option to only opened configured sessions
proc tsm(open: bool = false) =
  let
    project = selectProject(open)
    selected = project.name

  if selected notin tmux.sessions:
    tmux.new project.name, project.location
  else:
    tmux.attach project.name

when isMainModule:
  import cligen
  const vsn = staticExec "git describe --tags --always HEAD --match 'v*'"
  clCfg.version = vsn

  if clCfg.helpAttr.len == 0:
    clCfg.helpAttr = {"cmd": "\e[1;36m", "clDescrip": "", "clDflVal": "\e[33m",
        "clOptKeys": "\e[32m", "clValType": "\e[31m", "args": "\e[3m"}.toTable
    clCfg.helpAttrOff = {"cmd": "\e[m", "clDescrip": "\e[m", "clDflVal": "\e[m",
        "clOptKeys": "\e[m", "clValType": "\e[m", "args": "\e[m"}.toTable

  dispatch(
    tsm,
    short = {"version": 'v'},
  )
