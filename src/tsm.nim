import std/[algorithm, os, osproc, sequtils, strformat, strutils, sugar, tables,
    tempfiles, times]

const FZF_DEFAULT_ARGS = "--border-label='TSM: Tmux Session Manager' --ansi"

type
  Project = object
    location: string
    updated: Time
    open: bool # not used yet

proc listTmuxSessions(): seq[string] =
  let (output, _) = execCmdEx("tmux list-sessions -F '#S'")
  return output.splitLines()

proc fzf(projects: OrderedTable[string, Project], header: string): string =
  ## use fzf as a selector for the project
  let (inputFile, inPath) = createTempFile("tsm", "")
  let (outFile, outPath) = createTempFile("tsm", "")
  var FZF_ARGS = FZF_DEFAULT_ARGS

  if header != "":
    FZF_ARGS &= " --header-lines=1"
    inputFile.write header

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

proc name(p: Project): string = splitPath(p.location)[1].replace(".", "_")

proc newProject(path: string, sessions: seq[string]): Project =
  result.location = path
  result.updated = getLastModificationTime(path)
  result.open = splitPath(path)[1].replace(".", "_") in sessions

proc findProjects(): tuple[header: string, projects: OrderedTable[string, Project]] =
  ## get a table of possible project paths
  let tsmDirs = getEnv("TSM_DIRS")
  let sessions = listTmuxSessions()
  if tsmDirs == "":
    echo "Please set $TSM_DIRS to a colon-delimited list of paths"
    quit 1

  var projects: seq[Project]
  for devDir in tsmDirs.split(":"):
    for d in walkDir(devDir):
      projects.add newProject(d.path, sessions)

  projects.sort do (x, y: Project) -> int:
    result = cmp(y.open, x.open)
    if result == 0:
      result = cmp(y.updated, x.updated)

  for p in projects:
    if p.open: result.projects[&"\e[93m{p.name}\e[0m"] = p
    else: result.projects[p.name] = p

  if len(result.projects) != len(projects):
    echo "there may be nonunique entries in the project names"

  if projects.filterIt(it.open).len > 0:
    result.header = "\e[93m[open session]\e[0m\n"

proc checkFzf() =
  if findExe("fzf") == "":
    echo "tsm requires fzf"
    quit 1

when isMainModule:
  checkFzf()

  let (header, projects) = findProjects()
  let selected = fzf(projects, header)

  if existsEnv("TMUX"):
    if selected notin listTmuxSessions():
      discard execCmd(&"tmux new-session -d -s {selected} -c {projects[selected].location}")
    discard execCmd(&"tmux switch-client -t {selected}")
  else:
    if selected notin listTmuxSessions():
      discard execCmd(&"tmux new-session -s {selected} -c {projects[selected].location}")
    else:
      discard execCmd(&"tmux attach -t {selected}")
