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
    windows*: seq[Window]


proc pathToName*(path: string): string =
  splitPath(path)[1].replace(".", "_")

proc newProject*(path: string, open: bool = false, name = "", named: bool = false): Project =
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

proc minParts(paths: seq[seq[string]]): int =
  let max = paths.mapIt(it.len).min()
  var i = 1
  while i < max:
    if paths.mapIt(it[^i..^1]).toHashSet().len() == paths.len:
      return i
    inc i

  termQuit "failed to deduplicate these paths:" & paths.join(", ")

proc dedupedProjects( paths: seq[string]): seq[Project] =
  let pathSplits = paths.mapIt(it.split('/'))
  let nParts = minParts(pathSplits)

  for (p, s) in zip(paths, pathSplits):
    let name = s[^nParts..^1].join("/")
    result.add newProject(p, name = name)

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
    # assume session with the same name is the configured session
    if session.name notin openSessions:
      var p = newProject(path = session.path, name = session.name, named = true)
      p.windows = session.windows
      result.add p

type
  PathTable = Table[string, seq[string]]

proc `//`(a: var PathTable, b: PathTable) =
  for k, v in b.pairs:
    if a.hasKeyOrPut(k, v):
      a[k].add v

func pathToName(root: string, p: string): string =
  let parts = p.split('/')
  let n = parts.find(root)
  result = parts[n..^1].join("/")

proc getPaths(root: string, d: string, depth: Natural, level: Natural): PathTable =
  for (kind, path) in walkDir(d):
    # ignore files/links and hidden directories
    if ({kind} * {pcFile, pcLinkToFile}).len > 0 or path.splitPath.tail.startsWith("."):
      continue

    if depth == level:
      let name = (
        if depth != 0: pathToName(root, path)
        else: path.lastPathPart
      ).replace(".", "_")
      if result.hasKeyOrPut(name, @[path]):
        result[name].add path
    else:
      let root = if level == 0: path.lastPathPart else: root
      result // getPaths(root, path, depth, level + 1)

proc getPaths(r: Root): PathTable =
  let rootPath = r.path.lastPathPart
  getPaths(rootPath, r.path, r.depth, 0)

proc findProjectsFromRoots(roots: seq[Root], openSessions: var HashSet[string]): seq[Project] =
  var candidates: PathTable
  for root in roots:
    candidates // getPaths(root)

  for name, paths in candidates.pairs:
    if len(paths) == 1:
      result.add newProject(paths[0], name=name)
    else:
      result.add dedupedProjects(paths)

  # account for open sessions that overlap
  for p in result.mitems:
    if p.name in openSessions:
      p.open = true
      openSessions.excl p.name


proc findProjects*(open: bool = false): seq[Project] =
  let config = loadTsmConfig()
  var openSessions= tmux.sessions.mapIt(it.name).toHashSet()

  result.add findProjectsFromRoots(config.roots, openSessions)
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
    termError bb"nothing to select, check your [yellow]$TSM_PATHS[/] or config file"
    if config.roots.len > 0:
      termEcho "searched these directories: "
      hecho config.roots.mapIt("  " & it.path).join("\n")
    quit QuitFailure

  addInfo result
