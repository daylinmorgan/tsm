import std/[sequtils, os]
import ./[selector, project, tmuxutils, term]
import hwylterm, hwylterm/hwylcli

proc tsm(project: Project) =
  if project.name notin tmux.sessions.mapIt(it.name):
    tmux.new(project.name, project.location)
  else:
    tmux.attach project.name

const tsmVersion {.strDefine.} =
  staticExec "git describe --tags --always HEAD --match 'v*'"

hwylCli:
  name "tsm"
  V tsmVersion
  flags:
    open:
      ? "only search open sessions"
      - o
    new:
      ? "open session in current directory"
      - n
  run:
    if new and open:
      termQuit "--new and --open are mutually exclusive"

    let project =
      if new: newProject(
        path = getCurrentDir(),
        open = false,
      )
      else:
        selectProject findProjects(open)

    tsm(project)

