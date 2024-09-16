import std/[tables]

import selector, project, tmuxutils

# TODO: add option to only opened configured sessions
proc tsm(open: bool = false) =
  let
    projects = findProjects(open)
    project = selectProject projects
    selected = project.name

  if selected notin tmux.sessions:
    tmux.new(project.name, project.location)
  else:
    tmux.attach project.name

proc getVersion(): string =
  const tsmVersion {.strdefine.} = "unknown"
  const gitVersion = staticExec "git describe --tags --always HEAD --match 'v*'"
  when tsmVersion != "unknown": tsmVersion
  else: gitVersion


when isMainModule:
  import cligen
  clCfg.version = getVersion()

  if clCfg.helpAttr.len == 0:
    clCfg.helpAttr =
      {
        "cmd": "\e[1;36m",
        "clDescrip": "",
        "clDflVal": "\e[33m",
        "clOptKeys": "\e[32m",
        "clValType": "\e[31m",
        "args": "\e[3m"
      }.toTable
    clCfg.helpAttrOff =
      {
        "cmd": "\e[m",
        "clDescrip": "\e[m",
        "clDflVal": "\e[m",
        "clOptKeys": "\e[m",
        "clValType": "\e[m",
        "args": "\e[m"
      }.toTable

  dispatch(tsm, short = {"version": 'v'})
