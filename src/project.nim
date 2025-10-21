import std/[algorithm, os, sequtils, sets, strutils, sugar, tables, times]
import ./lib

type
  Project* = object
    named*: bool
    name*: string
    location*: string
    updated*: Time
    open*: bool
    matched*: bool
    tmuxinfo*: string

proc pathToName*(path: string): string =
  splitPath(path)[1].replace(".", "_")

proc newProject*(path: string, open: bool, name = "", named: bool = false): Project =
  result.location = path
  result.name =
    if name != "": name
    else: pathToName(path)
  result.updated = getLastModificationTime(path)
  result.open = open
  result.named = named

proc newUnknownProject*(name: string): Project =
  result.name = name
  result.open = true

proc findDuplicateProjects(
    paths: seq[string],
    sessions: var HashSet[string]
): seq[Project] =
  var candidates: Table[string, seq[string]]
  for p in paths:
    candidates[p] = p.split(DirSep)

  let maxExtra = min(candidates.values.toSeq.mapIt(it.len))
  for i in 2..maxExtra:
    let
      deduplicated =
        collect:
          for path, pathSplit in candidates.pairs:
            (name: pathSplit[^i..^1].joinPath, path: path)
    if deduplicated.mapIt(it[0]).toHashSet.len == candidates.len:
      for (name, path) in deduplicated:
        let open = name in sessions
        result.add newProject(path, open, name)
        if open:
          sessions.excl name
      break

  if result.len == 0:
    termQuit "failed to deduplicate these paths:" & paths.join(", ")

proc `<-`(candidates: var Table[string, seq[string]], path: string) =
  let name = path.splitPath.tail
  if candidates.hasKeyOrPut(name, @[path]):
    candidates[name].add path


func projectFromSession(s: TmuxSession): Project =
  result.name = s.name
  result.open = true
  result.tmuxinfo = s.info


proc addInfo(project: var seq[Project]) =
  ## naive fix to adding tmuxinfo until I rewrite findProjects
  let sessions = collect:
    for s in tmux.sessions:
      {s.name: s}
  for p in project.mitems:
    if p.name in sessions:
      p.tmuxinfo = sessions[p.name].info

proc newConfiguredProjects(c: Config, openSessions: HashSet[string]): seq[Project] =
  for session in c.sessions:
    if session.name notin openSessions:
      result.add newProject(path = session.path, open= false, name = session.name, named = true)

proc findProjectsFromPaths(paths: seq[string], openSessions: var HashSet[string]): seq[Project] =
  var candidates: Table[string, seq[string]]
  for d in paths:
    for (kind, path) in walkDir(d):
      if ({kind} * {pcFile, pcLinkToFile}).len > 0 or path.splitPath.tail.startsWith("."):
        continue
      candidates <- path

  for name, paths in candidates.pairs:
    if len(paths) == 1:
      let
        path = paths[0]
        open = path.pathToName in openSessions
      result.add newProject(path, open)
      if open:
        openSessions.excl path.pathToName
    else:
      result.add findDuplicateProjects(paths, openSessions)

proc findProjects*(open: bool = false): seq[Project] =
  let config = loadTsmConfig()
  var openSessions= tmux.sessions.mapIt(it.name).toHashSet()
 
  result.add findProjectsFromPaths(config.paths, openSessions)
  result.add newConfiguredProjects(config, openSessions)

  if open: result = result.filterIt(it.open)
  let sessionNames = config.sessionNames

  # order open -> configured -> mod time
  result.sort do(x, y: Project) -> int:
    result = cmp(y.open, x.open)
    if result == 0:
      result =
        if y.name in sessionNames:
          if x.name in sessionNames: cmp(y.name, x.name)
          else: 1
        elif x.name in sessionNames: -1
        else: cmp(y.updated, x.updated)

  # add the remaining open sessions I didn't create
  if openSessions.len > 0:
    result = tmux.sessions.filterIt(it.name in openSessions).mapIt(projectFromSession(it)) & result

  if len(result) == 0:
    if open:
      termQuit "no open sessions"
    termError bb"nothing to select, check your [yellow]$TSM_PATHS[/]"
    if config.paths.len > 0:
      termEcho "searched these directories: "
      echo config.paths.mapIt("  " & it).join("\n")
    quit QuitFailure

  addInfo result
