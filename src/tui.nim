import std/[enumerate, os, sequtils, strformat, strutils]

import illwill
import project

proc quitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()

template withfgColor(fgColor, body: untyped) =
  var tb = state.buffer
  tb.setForegroundColor(fgColor, bright = true)
  body
  tb.setForegroundColor(fgWhite, bright = true)

type
  Coord = object
    x1, x2, y1, y2: int

  Cursor = object
    min, max, y: Natural

  Window = object
    coord: Coord
    tooSmall: bool

  State = object
    buffer: TerminalBuffer
    lastKey: Key
    input: string
    window: Window
    cursor: Cursor
    projectIdx: Natural
    projects: seq[Project]


# TODO: don't need top level projects
# let (_, projects) = findProjects()
var state = State()

proc values(c: Coord): (int, int, int, int) = (c.x1, c.x2, c.y1, c.y2)

proc height(w: Window): int = w.coord.y2 - (w.coord.y1)
proc width(w: Window): int = return w.coord.x2-w.coord.x1

proc scrollUp() =
  if state.projectIdx > 0:
    dec state.projectIdx

proc scrollDown() =
  if (state.projects.len - state.projectIdx) > state.window.height + 1:
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

proc backspace(s: string): string =
  if s != "": result = s[0..^2]

func toStr(k: Key): string = $chr(ord(k))

proc match(project: Project): Project =
  result = project
  result.matched = true

# TODO: convert this into a proper sorter
proc sortProjects(): seq[Project] =

  var
    priority: seq[Project]
    rest: seq[Project]

  if state.input != "":
    for project in state.projects:
      if project.name.startsWith(state.input):
        priority &= project.match()
      else:
        rest &= project
    return priority & rest
  else:
    return state.projects.toSeq()

proc getProject(): Project =
  let projects = sortProjects()
  var idx = state.cursor.y - state.cursor.min + state.projectIdx
  return projects[idx]


proc clip(s: string): string =
  let maxWidth = state.window.width - 2
  result =
    if s.len > maxWidth:
      s[0..^state.window.width]
    else: s

proc displayProject(tb: var TerminalBuffer, x, y: int, project: Project) =
  let
    name = project.name.clip
    input = state.input.clip
    projectColor = if project.open: fgYellow else: fgWhite

  if project.matched:
    withfgColor fgRed:
      tb.write(x, y, name)
    withfgColor projectColor:
      tb.write(x+input.len, y, name[input.len..^1])
  else:
    withfgColor projectColor:
      tb.write(x, y, name)

proc displayProjects(tx, ty: int) =
  let projects = sortProjects()
  var
    line = ty + 2
    tb = state.buffer

  for (i, project) in enumerate(projects):
    if i < state.projectIdx:
      continue

    tb.displayProject(tx, line, project)
    if line > state.window.coord.y2-2: break
    inc line

  tb.write(tx-2, state.cursor.y, "> ")


when defined(debug):
  proc `$`(c: Coord): string = &"(x1:{c.x1}, x2: {c.x2}, y1: {c.y1}, y2: {c.y2})"
  proc debugInfo() =
    var tb = state.buffer
    let
      (x, y) = (2, 1)
      lines = @[
        &"heights -> buffer: {tb.height}, window: {state.window.height}",
        &"widths -> buffer: {tb.width}, window: {state.window.width}",
        "project: " & getProject().name,
        "state:",
        "|  last key   -> " & $state.lastKey,
        "|  cursor     -> " & "y:" & $state.cursor.y,
        "|  projectIdx -> " & $state.projectIdx,
        "|  window     -> " & $state.window.coord,
        ]
    for i, line in lines:
      tb.write(x, y+i, line)

proc draw() =
  var
    tb = state.buffer
    input = state.input

  tb.setForegroundColor(fgWhite, bright = true)

  let
    (x1, x2, y1, y2) = state.window.coord.values()
    maxWidth = x2 - x1 - 4

  when defined(debug):
    debugInfo()
    withfgColor fgRed:
      tb.drawRect(x1, y1, x2, y2)

  tb.drawHorizLine(x1+1, x2-1, y1+2)

  if input.len > maxWidth:
    input = "..." & input[^(maxWidth-3)..^1]

  tb.write(x1+1, y1+1, "$ " & input)
  displayProjects(x1+3, y1+1)
  tb.display()

proc reset() = state.cursor.y = state.cursor.min

proc update(c: var Cursor, min, max: Natural) =
  c.min = min
  c.max = max
  if c.y > max: c.y = max
  elif c.y < min: c.y = min

proc getCoords(): Coord =
  var width, height: Natural
  let (termWidth, termHeight) = terminalSize()
  width = if termWidth > 65: 65 else: termWidth
  height = if termHeight > 20: 20 else: termHeight

  # fullscreen type behavior
  result.x1 = ((termWidth - width)/2).int
  result.y1 = ((termHeight - height)/2).int
  result.x2 = result.x1 + width
  result.y2 = result.y1 + height

proc drawSizeWarning(tb: var TerminalBuffer) =
  let (termWidth, termHeight) = terminalSize()
  withfgColor fgRed:
    tb.write(0, 0, "window is too small")
  withfgColor fgYellow:
    tb.write(0, 1, &"WxH: {termWidth}x{termHeight}")
  tb.write(0, 2, "need 15x10")
  tb.display()

proc newWindow(): Window =
  state.buffer = newTerminalBuffer(terminalWidth(), terminalHeight())
  result.coord = getCoords()
  state.cursor.update(min = result.coord.y1+3, max = result.coord.y2-1)
  result.tooSmall = (result.width < 15 or result.height < 10)

proc selectProject*(open: bool = false): Project =

  state.projects = findProjects(open)
  illwillInit(fullscreen = true)
  setControlCHook(quitProc)
  hideCursor()

  while true:
    state.window = newWindow()
    if state.window.tooSmall:
      state.buffer.drawSizeWarning()
      continue
    var key = getKey()
    case key
    of Key.None: discard
    of Key.Escape: quitProc()
    of Key.Enter:
      exitProc()
      return getProject()
    of Key.Up:
      up()
    of Key.Down:
      down()
    of Key.CtrlA..Key.CtrlL, Key.CtrlN..Key.CtrlZ, Key.CtrlRightBracket,
        Key.CtrlBackslash, Key.Right..Key.F12:
      state.lastKey = key
    else:
      state.lastKey = key
      reset()
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
  let selected = selectProject()
  echo "selected project -> " & $selected.name


