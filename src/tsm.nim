import ./[selector, project, tmuxutils]

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


when isMainModule:
  import std/parseopt
  import hwylterm, hwylterm/cli

  const tsmVersion {.strdefine.} = staticExec "git describe --tags --always HEAD --match 'v*'"
  proc help() =
    echo newHwylCli(
      """tmux session manager

[bold]tsm[/] [[[faint]-h|-v|-o[/]]""",

      flags = [
        ("h","help","show this help"),
        ("v","version", "print version"),
        ("o","open", "only search open sessions")
      ]
    )
  var open: bool
  var p = initOptParser(
    shortNoVal = {'h', 'v', 'o'},
    longNoVal = @["open"]
  )
  for kind, key, val in p.getOpt():
    case kind:
    of cmdEnd:
      break
    of cmdArgument:
      echo bb"[red]Error[/]: unexpected positional argument ", bbfmt"[bold]{key}[/]"
    of cmdShortOption, cmdLongOption:
      case key:
      of "help", "h":
        help(); quit 0
      of "version", "v":
        echo "tsm: " & tsmVersion; quit 0
      of "open", "o":
        open = true
      else:
        echo bbfmt"[red]Error[/]: unknown key value pair", bbfmt"[b]key[/]: {key}, [b]value[/]: {val}"

  tsm(open)
