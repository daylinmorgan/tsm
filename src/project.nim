import std/[algorithm, os, strutils, times]

import utils

type
  Project* = object
    location*: string
    updated*: Time
    open*: bool
    matched*: bool

proc newProject(path: string, sessions: seq[string]): Project =
  result.location = path
  result.updated = getLastModificationTime(path)
  result.open = splitPath(path)[1].replace(".", "_") in sessions

proc name*(p: Project): string = splitPath(p.location)[1].replace(".", "_")

proc findProjects*(open: bool = false): seq[Project] =
  ## get a table of possible project paths
  # TODO: improve this to handle duplicate entries by appending parent?
  let
    tsmDirs = getEnv("TSM_DIRS")

  if tsmDirs == "":
    echo "Please set $TSM_DIRS to a colon-delimited list of paths"
    quit 1

  # TODO: only return directories
  for devDir in tsmDirs.split(":"):
    for d in walkDir(devDir):
      let p = newProject(d.path, tmux.sessions)
      if open and p.open: result.add p
      else:
        result.add p

  if len(result) == 0:
    echo "nothing to select"
    quit 1

  # TODO: use the input as a first filter?

  # favor open projects then by update time
  result.sort do (x, y: Project) -> int:
    result = cmp(y.open, x.open)
    if result == 0:
      result = cmp(y.updated, x.updated)

  # for p in projects:
  #   result.projects[p.name] = p

  # if len(result.projects) != len(projects):
  #   echo "there may be nonunique entries in the project names"

