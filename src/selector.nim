import std/[enumerate, os, strformat, strutils, terminal]
import hwylterm
from hwylterm/vendor/illwill import illwillDeinit, illwillInit, getKey, Key
import term, project

func toStr(k: Key): string =
  $chr(ord(k))

proc getMaxHeight(): int =
  result = 10
  let setting = getEnv("TSM_HEIGHT")
  if setting != "":
    try:
      result = parseInt(setting)
    except ValueError:
      termQuit fmt"failed to parse TSM_HEIGHT of `{setting}`, expected integer"

let maxHeight = getMaxHeight()

type
  Cursor = object
    min, y: Natural = 1
    max: Natural

  Buffer = object
    height: Natural
    width: Natural
    buffer: string
    inputPad: Natural = 3

  State = object
    buffer: Buffer
    lastKey: Key
    input: string
    cursor: Cursor
    projectIdx: Natural
    projects: seq[Project]
    selected: seq[Natural]

var state = State()

func clip(
  s: string,
  width: int = state.buffer.width - 3
): string =
  result =
    if s.len > width: s[0..width]
    else: s

func highlight(p: Project): string =
  if p.location == "": "green"
  elif p.open: "bold yellow"
  elif p.named: "cyan"
  else: "default"

proc display(s: State, p: Project): Bbstring =
  let
    name = p.name.clip
    input = s.input.clip

  if p.matched:
    result.add input.bb("red")
    if input.len < name.len:
      result.add ($name[input.len..^1]).bb(p.highlight)
  else:
    result.add name.bb(p.highlight)

  if p.tmuxinfo != "":
    # will fail without clip!
    result.add p.tmuxinfo.bb("faint")

  result.truncate(state.buffer.width - 5)

func addLine(b: var Buffer, text: string) =
  b.buffer.add ("  " & text).alignLeft(b.width) & "\n"

func addDivider(b: var Buffer) =
  b.addLine "─".repeat(b.width - 2)

proc addInput(b: var Buffer) =
  var line = "$ "
  if state.input != "":
    line.add state.input
  else:
    line.add $pathToName(getCurrentDir()).bb("faint")
  b.addLine line

func numLines(b: Buffer): int =
  b.buffer.count '\n'

proc draw(b: var Buffer) =
  while b.numLines < b.height:
    b.addLine ""
  stdout.write(b.buffer)

  when defined(debugSelect):
    stdout.writeLine ""
    stdout.writeLine "DEBUG INFO:"
    stdout.writeLine $state.cursor
    stdout.writeLine alignLeft("Key: " & $(state.lastKey), b.Buffer.width)
    stdout.writeLine "(w: $1, h: $2)" % [$b.width, $b.height]
    stdout.writeLine "-".repeat(b.width)
    stdout.cursorUp  b.numLines + 6
  else:
    stdout.cursorUp(b.numLines)
  stdout.flushFile()

proc scrollUp() =
  if state.projectIdx > 0:
    dec state.projectIdx

proc scrollDown() =
  if (state.projects.len - state.projectIdx) > (
    state.buffer.height - state.buffer.inputPad
  ):
    inc state.projectIdx

proc up() =
  if state.cursor.y > state.cursor.min:
    dec state.cursor.y
  elif state.cursor.y == state.cursor.min:
    scrollUp()

proc down() =
  if state.cursor.y < state.cursor.max:
    inc state.cursor.y
  elif state.cursor.y == state.cursor.max:
    scrollDown()

func backspace(s: string): string =
  if s != "":
    result = s[0..^2]

func match(project: Project): Project =
  result = project
  result.matched = true

# TODO: convert this into a proper sorter
proc sortProjects(): seq[Project] =
  var
    priority: seq[Project]
    rest: seq[Project]
  if state.input == "":
    return state.projects

  for project in state.projects:
    if project.name.startsWith(state.input):
      priority &= project.match()
    else:
      rest &= project
  return priority & rest

proc getProject(): Project =
  # NOTE: do i need to call sortProjects again here?
  let projects = sortProjects()
  var idx = state.cursor.y - state.cursor.min + state.projectIdx
  return projects[idx]


proc addInfoLine(b: var Buffer) =
  let
    maxNumProjects = state.buffer.height - state.buffer.inputPad
    numProjects = state.projects.len
    low = state.projectIdx + 1
    high = state.projectIdx + min(maxNumProjects, numProjects)
    infoLine = fmt"[[{low}-{high}/{numProjects}] Ctrl+E to new session"
  b.addLine $(infoLine.clip(state.buffer.width - 2).bb("faint"))

proc addProjects(b: var Buffer) =
  let
    # NOTE: is a bounds error possible?
    nProjects = min(state.buffer.height - state.buffer.inputPad, state.projects.len() - state.projectIdx)
    slice = state.projectIdx..<(state.projectIdx + nProjects)
    projects = sortProjects()[slice]

  for (i, project) in enumerate(projects):
    let cursorArrow =
      if state.cursor.y == i + 1: "> "
      else: "  "
    b.addLine(cursorArrow & $display(state, project))

proc reset() =
  state.cursor.y = state.cursor.min
  state.projectIdx = 0

proc draw() =
  var buffer = state.buffer
  buffer.addInput
  buffer.addDivider
  buffer.addInfoLine
  buffer.addProjects
  buffer.draw

proc update(s: var State) =
  s.buffer.width = terminalWidth()
  s.buffer.height =
    min(
      [
        terminalHeight(),
        maxHeight + state.buffer.inputPad,
        state.buffer.inputPad + state.projects.len
      ]
    )
  s.cursor.max = s.buffer.height - state.buffer.inputPad

proc clear(b: var Buffer) =
  b.buffer = ""
  b.draw

proc quitProc() {.noconv.} =
  illwillDeinit()
  state.buffer.clear
  showCursor()
  quit(0)

proc exitProc() {.noconv.} =
  illwillDeinit()
  state.buffer.clear
  showCursor()

proc selectProject*(projects: seq[Project]): Project =
  state.projects = projects
  illwillInit(fullscreen = false)
  setControlCHook(quitProc)
  hideCursor()

  while true:
    state.update()
    var key = getKey()
    case key
    of Key.None:
      discard
    of Key.Escape:
      quitProc()
    of Key.Enter:
      exitProc()
      return getProject()
    of Key.Up:
      up()
    of Key.Down:
      down()
    of Key.CtrlE:
      exitProc()
      return newProject(
        path = getCurrentDir(),
        name = state.input,
        open = false,
      )
    of
        Key.CtrlA..Key.CtrlD,
        Key.CtrlF..Key.CtrlL,
        Key.CtrlN..Key.CtrlZ,
        Key.CtrlRightBracket,
        Key.CtrlBackslash,
        Key.Right..Key.F12:
      state.lastKey = key
    else:
      reset()
      state.lastKey = key
      case key
      of Key.Backspace:
        state.input = state.input.backspace
      of Key.Space..Key.Z:
        state.input &= key.toStr
      else:
        state.input &= $key

    draw()
    sleep(10)

when isMainModule:
  let projects = findProjects(false)
  let selected = selectProject(projects)
  echo "selected project -> " & $selected
