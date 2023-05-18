import std/[algorithm, os, osproc, strformat, strutils, sugar, tables, tempfiles, times]

const FZF_ARGS = "--border-label='TSM: Tmux Session Manager'"

type
  Project = object
    location: string
    updated: Time
    open: bool # not used yet


proc fzf(projects: OrderedTable[string, Project]): string =
  ## use fzf as a selector for the project
  let (inputFile, inPath) = createTempFile("tsm", "")
  let (outFile, outPath) = createTempFile("tsm", "")

  inputFile.write collect(for k in projects.keys(): k).join("\n")
  close inputFile

  let errCode = execCmd(&"fzf {FZF_ARGS} < {inPath} > {outPath}")
  close outFile

  if errCode != 0: echo &"fzf exited with code: {errCode}"

  result = readFile(outPath)
  result.stripLineEnd()
  if result == "":
    quit errCode

  removeFile(inPath)
  removeFile(outPath)

proc findProjects(): OrderedTable[string, Project] =
  ## get a table of possible project paths
  let tsmDirs = getEnv("TSM_DIRS")

  if tsmDirs == "":
    echo "Please set $TSM_DIRS to a colon-delimited list of paths"
    quit 1

  var projectPaths: seq[Project]
  for devDir in tsmDirs.split(":"):
    for d in walkDir(devDir):
      projectPaths.add Project(location:d.path, updated: getLastModificationTime(d.path), open: false)

  projectPaths.sort do (x,y: Project) -> int:
    cmp(y.updated, x.updated)

  for p in projectPaths:
    let name = splitPath(p.location)[1].replace(".","_")
    result[name] = p

  if len(result) != len(projectPaths):
    echo "there may be nonunique entries in the project names"

proc listTmuxSessions(): seq[string] =
  let (output, _) = execCmdEx("tmux list-sessions -F '#S'")
  return output.splitLines()

proc checkFzf() =
  if findExe("fzf") == "":
    echo "tsm requires fzf"
    quit 1

when isMainModule:
  checkFzf()

  let projects = findProjects()
  let selected = fzf(projects)

  if existsEnv("TMUX"):
    if selected notin listTmuxSessions():
      discard execCmd(&"tmux new-session -d -s {selected} -c {projects[selected].location}")
    discard execCmd(&"tmux switch-client -t {selected}")
  else:
    if selected notin listTmuxSessions():
      discard execCmd(&"tmux new-session -s {selected} -c {projects[selected].location}")
    else:
      discard execCmd(&"tmux attach -t {selected}")
