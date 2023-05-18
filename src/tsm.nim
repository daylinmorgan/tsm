import std/[algorithm, os, osproc, sequtils, strformat, strutils, sugar, tables,
    tempfiles, times]

const fzfDefaultArgs = "--border-label='TSM: Tmux Session Manager' --ansi"


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

  let 
    (inputFile, inPath) = createTempFile("tsm", "")
    (outFile, outPath) = createTempFile("tsm", "")

  var fzfArgs = fzfDefaultArgs

  if header != "":
    fzfArgs &= " --header-lines=1"
    inputFile.write header

  inputFile.write collect(for k in projects.keys(): k).join("\n")
  close inputFile

  let errCode = execCmd(&"fzf {fzfArgs} < {inPath} > {outPath}")
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

proc findProjects(open: bool): tuple[header: string, projects: OrderedTable[string, Project]] =
  ## get a table of possible project paths

  let 
    tsmDirs = getEnv("TSM_DIRS")
    sessions = listTmuxSessions()

  if tsmDirs == "":
    echo "Please set $TSM_DIRS to a colon-delimited list of paths"
    quit 1

  var projects: seq[Project]
  for devDir in tsmDirs.split(":"):
    for d in walkDir(devDir):
      let p = newProject(d.path, sessions)

      if open:
        if p.open: projects.add p
      else: 
        projects.add p

  if len(projects) == 0:
    echo "nothing to select"
    quit 1

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

proc tsm(open:bool = false) =
  checkFzf()

  let (header, projects) = findProjects(open)
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

when isMainModule:
  import cligen
  const vsn = staticExec "git describe --tags --always --dirty=-dev"
  clCfg.version = vsn

  dispatch(
    tsm, 
    short={"version":'v'},
    help={"open":"only show open sessions"}
    )

