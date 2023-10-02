import std/[algorithm, os, sequtils, sets, strutils, tables, times]

import bbansi
import utils

type
  Project* = object
    name*: string
    location*: string
    updated*: Time
    open*: bool
    matched*: bool

proc pathToName(path: string): string = splitPath(path)[1].replace(".", "_")

proc newProject(path: string, open: bool): Project =
  result.location = path
  result.name = path.pathToName()
  result.updated = getLastModificationTime(path)
  result.open = open

proc newUnknownProject(name: string): Project =
  result.name = name

proc getTsmDirs(): seq[string] =
  let tsmDirs = getEnv("TSM_DIRS")
  if tsmDirs == "":
    bbEcho "[red]Please set [cyan]$TSM_DIRS[/] to a colon-delimited list of paths"
    quit QuitFailure
  result = tsmDirs.split(":")

proc findProjects*(open: bool = false): seq[Project] =
  var candidates: Table[string, seq[string]]
  var sessions = tmux.sessions.toHashSet()

  for devDir in getTsmDirs():
    for path in walkDir(devDir):
      if ({path.kind} * {pcFile, pcLinkToFile}).len > 0: continue
      let name = path.path.tailDir()
      if name in candidates:
        candidates[name].add path.path
      else:
        candidates[name] = @[path.path]

  # TODO: improve this to handle duplicate entries by appending parent?
  for name, paths in candidates:
    if len(paths) == 1:
      let path = paths[0]
      let open = path.pathToName in sessions
      result.add newProject(path, open)
      if open:
        sessions.excl toHashSet([path.pathToName])

  if open:
    result = result.filterIt(it.open)

  # favor open projects then by update time
  result.sort do (x, y: Project) -> int:
    result = cmp(y.open, x.open)
    if result == 0:
      result = cmp(y.updated, x.updated)

  if sessions.len > 0:
    result = sessions.toSeq().mapIt(newUnknownProject(it)) & result

  if len(result) == 0:
    echo "nothing to select"
    quit 1


