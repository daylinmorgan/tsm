import std/[os, osproc, strformat, strutils]

type
  Tmux = object
    active: bool
    sessions*: seq[string]

proc checkExe(names: varargs[string]) =
  for name in names:
    if findExe(name) == "":
      echo "tsm requires " & name

checkExe "tmux"

proc cmdGet(tmux: Tmux, args: string): string =
  let (output, code) = execCmdEx("tmux " & args)
  if code != 0:
    echo "ERROR: failed to run: tmux ", args, "see below for error"
    echo output
    quit QuitFailure
  return output

template cmd(tmux: Tmux, args: string) =
  discard execCmd("tmux " & args)

proc newTmux(): Tmux =
  result.active = existsEnv("TMUX")
  # check if server is active?
  if execCmd("tmux run") == 0:
    result.sessions = (
      result.cmdGet "list-sessions -F '#S'"
    ).strip().split("\n")

proc attach*(t: Tmux, session: string) =
  let args =
    if t.active: "switch-client -t"
    else: "attach -t"
  t.cmd fmt"{args} {session}"

proc new*(t: Tmux, session: string, loc: string) =
  let args =
    if t.active: "new-session -d"
    else: "new-session"
  t.cmd fmt"{args} -s {session} -c {loc}"

let tmux* = newTmux()
