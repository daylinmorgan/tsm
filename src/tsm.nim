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
  import cligen, hwylterm, hwylterm/cli
  clCfg.version = getVersion()
  hwylCli(clCfg)
  let clUse* = $bb("$command $args\n${doc}[bold]Options[/]:\n$options")
  dispatch(tsm, usage = clUse, short = {"version": 'v'})
