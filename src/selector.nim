import std/[enumerate, os, strformat, strutils, terminal]

from illwill import illwillDeinit, illwillInit, getKey, Key
import bbansi

import project

func toStr(k: Key): string = $chr(ord(k))

type
  Cursor = object
    min, y: Natural = 1
    max: Natural

  Buffer = object
    height: int
    width: int
    buffer: string
    inputPad: int = 3

  State = object
    buffer: Buffer
    lastKey: Key
    input: string
    cursor: Cursor
    projectIdx: Natural
    projects: seq[Project]

var state = State()

proc addLine(b: var Buffer, text: string) =
  b.buffer.add ("  " & text).alignLeft(b.width) & "\n"

proc addDivider(b: var Buffer) =
  b.addLine "─".repeat(b.width-2)

proc addInput(b: var Buffer) =
  b.addLine "$ " & state.input

proc numLines(b: Buffer): int =
  b.buffer.count '\n'

proc draw(b: var Buffer) =
  while b.numLines < b.height:
    b.addLine ""

  stdout.write(b.buffer)

  when defined(debug):
    stdout.writeLine ""
    stdout.writeLine "DEBUG INFO -------------"
    stdout.writeLine $state.cursor
    stdout.writeLine(
      alignLeft("Key: " & $(state.lastKey), b.Buffer.width)
    )
    stdout.cursorUp(b.numLines + 4)
  else:
    stdout.cursorUp(b.numLines)
  stdout.flushFile()

proc scrollUp() =
  if state.projectIdx > 0:
    dec state.projectIdx

proc scrollDown() =
  if (state.projects.len - state.projectIdx) > (state.buffer.height -
      state.buffer.inputPad):
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

proc match(project: Project): Project =
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
  let projects = sortProjects()
  var idx = state.cursor.y - state.cursor.min + state.projectIdx
  return projects[idx]


proc clip(s: string): string =
  let maxWidth = state.buffer.width - 2
  result =
    if s.len > maxWidth:
      s[0..^maxWidth]
    else: s

proc addProject(b: var Buffer, project: Project, selected: bool) =
  let
    name = project.name.clip
    input = state.input.clip
    projectColor = if project.open: "yellow" else: "default"
    cur = (if selected: "> " else: "  ")

  if project.matched:
    var displayName = $input.bb("red")
    if input.len < name.len:
      displayName.add $name[input.len..^1].bb(projectColor)
    b.addLine(cur & $displayName)
  else:
    b.addLine(cur & $name.bb(projectColor))

proc addProjectCount(b: var Buffer) =
  let
    maxNumProjects = state.buffer.height - state.buffer.inputPad
    numProjects = state.projects.len
  b.addLine $(fmt"[[{state.projectIdx+1}-{state.projectIdx + maxNumProjects}/{numProjects}]".bb("faint"))

proc addProjects(b: var Buffer) =
  let
    projects = sortProjects()
    maxNumProjects = state.buffer.height - state.buffer.inputPad

  var numProjects = 1
  for (i, project) in enumerate(projects[state.projectIdx..^1]):
    b.addProject(project, state.cursor.y == numProjects)
    inc numProjects
    if numProjects > maxNumProjects: break

proc reset() =
  state.cursor.y = state.cursor.min
  state.projectIdx = 0

proc draw() =
  var buffer = state.buffer
  buffer.addInput
  buffer.addDivider
  buffer.addProjectCount
  buffer.addProjects
  buffer.draw

proc update(s: var State) =
  s.buffer.width = terminalWidth()
  s.buffer.height = min(terminalHeight(), 10 + state.buffer.inputPad)
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

proc selectProject*(open: bool = false): Project =

  state.projects = findProjects(open)
  illwillInit(fullscreen = false)
  setControlCHook(quitProc)
  hideCursor()

  while true:
    state.update()
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
  let selected = selectProject()
  echo "selected project -> " & $selected.name

