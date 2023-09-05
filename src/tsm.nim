import std/[os, osproc, strformat, tables]

import tui, project

proc checkExe(names: varargs[string]) =
  for name in names:
    if findExe(name) == "":
      echo "tsm requires " & name

proc tsm() =
  checkExe "tmux"

  let
    project = selectProject()
    selected = project.name

  # TODO: refactor
  if existsEnv("TMUX"):
    if selected notin listTmuxSessions():
      discard execCmd(&"tmux new-session -d -s {selected} -c {project.location}")
    discard execCmd(&"tmux switch-client -t {selected}")
  else:
    if selected notin listTmuxSessions():
      discard execCmd(&"tmux new-session -s {selected} -c {project.location}")
    else:
      discard execCmd(&"tmux attach -t {selected}")

when isMainModule:
  import cligen
  const vsn = staticExec "git describe --tags --always HEAD"
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
