import ./[selector, project, tmuxutils]
import hwylterm, hwylterm/hwylcli

proc tsm(open: bool = false) =
  let
    projects = findProjects(open)
    project = selectProject projects
    selected = project.name

  if selected notin tmux.sessions:
    tmux.new(project.name, project.location)
  else:
    tmux.attach project.name

hwylCli:
  name "tsm"
  V tsmVersion
  flags:
    open "only search open sessions"
  run:
    tsm(open)

