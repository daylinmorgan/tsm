import std/[algorithm, os, sequtils, sets, strutils, sugar, tables, times]
import tmuxutils, term

type
  Project* = object
    name*: string
    location*: string
    updated*: Time
    open*: bool
    matched*: bool

proc pathToName(path: string): string = splitPath(path)[1].replace(".", "_")

proc newProject(path: string, open: bool, name = ""): Project =
  result.location = path
  result.name =
    if name != "": name
   else: path.pathToName()
  result.updated = getLastModificationTime(path)
  result.open = open

proc newUnknownProject(name: string): Project =
  result.name = name
  result.open = true

proc getTsmDirs(): seq[string] =
  let tsmDirs = getEnv("TSM_DIRS")
  if tsmDirs == "":
    termQuit "Please set [yellow]$TSM_DIRS[/] to a colon-delimited list of paths"
  result = tsmDirs.split(":")

proc findDuplicateProjects(paths: seq[string],
    sessions: var HashSet[string]): seq[Project] =
  var candidates: Table[string, seq[string]]
  for p in paths:
    candidates[p] = p.split(DirSep)

  let maxExtra = min(candidates.values.toSeq.mapIt(it.len))
  for i in 2..maxExtra:
    let deduplicated = collect:
      for path, pathSplit in candidates.pairs:
        (name: pathSplit[^i..^1].joinPath, path: path)
    if deduplicated.mapIt(it[0]).toHashSet.len == candidates.len:
      for (name, path) in deduplicated:
        let open = name in sessions
        result.add newProject(path, open, name)
        if open: sessions.excl name
      break

  if result.len == 0:
    termQuit "failed to deduplicate these paths:" & paths.join(", ")

proc findProjects*(open: bool = false): seq[Project] =
  var candidates: Table[string, seq[string]]
  var sessions = tmux.sessions.toHashSet()

  for devDir in getTsmDirs():
    for path in walkDir(devDir):
      if ({path.kind} * {pcFile, pcLinkToFile}).len > 0: continue
      let name = path.path.splitPath.tail
      if candidates.hasKeyOrPut(name, @[path.path]):
        candidates[name].add path.path

  for name, paths in candidates.pairs:
    if len(paths) == 1:
      let
        path = paths[0]
        open = path.pathToName in sessions
      result.add newProject(path, open)
      if open: sessions.excl path.pathToName
    else:
      result &= findDuplicateProjects(paths, sessions)

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
    termError "nothing to select, check your [yellow]$TSM_DIRS"
    termEcho "searched these directories: "
    echo getTsmDirs().mapIt("  " & it).join("\n")
    quit QuitFailure

