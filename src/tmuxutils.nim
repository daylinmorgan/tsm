import std/[os, osproc, strformat, strutils, sequtils]

import term

type
  TmuxSession* = object
    name*: string
    info*: string
  Tmux* = object
    active*: bool
    sessions*: seq[TmuxSession]

proc checkExe(names: varargs[string]) =
  for name in names:
    if findExe(name) == "":
      termError "tsm requires " & name

checkExe "tmux"

proc tmuxError(args: string, output: string = "") =
  termError "failed to run: [bold]tmux", args
  if output != "":
    termError "see below for error"
    echo output
  quit QuitFailure

proc cmdGet(tmux: Tmux, args: string): string =
  let (output, code) = execCmdEx("tmux " & args)
  if code == 0:
    return output
  tmuxError args, output

template cmd(tmux: Tmux, args: string) =
  let code = execCmd "tmux " & args
  if code != 0:
    tmuxError(args)

proc toSession(s: string): TmuxSession = 
  let ss = s.split(":", 1)
  if ss.len != 2:
    tmuxError "failed to parse session info from: " & s
  result.name = ss[0]
  result.info = ss[1]

proc newTmux(): Tmux =
  result.active = existsEnv("TMUX")
  # check if server is active
  if execCmdEx("tmux run").exitCode == 0:
    result.sessions = (result.cmdGet "list-sessions").strip().split("\n").mapIt(toSession(it))

proc attach*(t: Tmux, session: string) =
  let args = if t.active: "switch-client -t" else: "attach -t"
  t.cmd fmt"{args} {session}"

proc new*(t: Tmux, session: string, loc: string) =
  if t.active:
    t.cmd fmt"new-session -d -s {session} -c {loc}"
    t.attach session
  else:
    t.cmd fmt"new-session -s {session} -c {loc}"

let tmux* = newTmux()
