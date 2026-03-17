import std/[os, osproc, strformat, strutils]
import ./[config, term]
export config, term

type
  TmuxSession* = object
    name*: string
    info*: string
    current*: bool
  Tmux* = object
    active*: bool
    sessions*: seq[TmuxSession]

proc checkExe(names: varargs[string]) =
  for name in names:
    if findExe(name) == "":
      termError "tsm requires " & name

checkExe "tmux"

proc tmuxError(args: string, output: string = "") =
  termError bb"failed to run: [bold]tmux",  args
  if output != "":
    termError "see below for error"
    hecho output
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

proc getSessions(tmux: var Tmux) =
  let currentName = tmux.cmdGet "display-message -p '#S'"
  for info in tmux.cmdGet("list-sessions").strip().splitLines():
    var session = toSession(info)
    if session.name == currentName:
      session.current = true
    tmux.sessions.add session

proc newTmux(): Tmux =
  result.active = existsEnv("TMUX")
  # check if server is active
  if execCmdEx("tmux run").exitCode == 0:
    result.getSessions()

proc attach*(t: Tmux, session: string) =
  let args = if t.active: "switch-client -t" else: "attach -t"
  t.cmd fmt"{args} {session.quoteShell()}"

proc new*(t: Tmux, session: string, loc: string, windows: seq[Window] = @[]) =
  t.cmd fmt"new-session -d -s {session.quoteShell()} -c {loc.quoteShell()}"
  if windows.len > 0:
    for w in windows:
      var cmd = fmt"new-window -t {session.quoteShell()} -n {w.name.quoteShell()} -c {loc.quoteShell()}"
      if w.exec != "":
        cmd &= " " & quoteShell(w.exec)
      t.cmd cmd
  t.attach session


let tmux* = newTmux()
