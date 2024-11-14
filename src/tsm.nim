import std/sequtils
import ./[selector, project, tmuxutils]
import hwylterm, hwylterm/hwylcli

proc tsm(open: bool = false) =
  let
    projects = findProjects(open)
    project = selectProject projects
    selected = project.name

  if selected notin tmux.sessions.mapIt(it.name):
    tmux.new(project.name, project.location)
  else:
    tmux.attach project.name

const tsmVersion {.strDefine.} =
  staticExec "git describe --tags --always HEAD --match 'v*'"

hwylCli:
  name "tsm"
  V tsmVersion
  flags:
    open "only search open sessions"
  run:
    tsm(open)

