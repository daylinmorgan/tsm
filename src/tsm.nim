import std/[os, osproc, strformat, strutils, sugar, tables, tempfiles]

const FZF_ARGS = "--border-label='TSM: Tmux Session Manager'"

proc pickProject(projects: Table[string, string]): string =
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

  removeFile(inPath)
  removeFile(outPath)

proc findProjects(): Table[string, string] =
  ## get a table of possible project paths
  let tsmDirs = getEnv("TSM_DIRS")

  if tsmDirs == "":
    echo "Please set $TSM_DIRS to a colon-delimited list of paths"
    quit 1

  var projectPaths: seq[string]
  for devDir in tsmDirs.split(":"):
    for d in walkDir(devDir):
      projectPaths.add d.path

  result = collect(for p in projectPaths: {splitPath(p)[1].replace(".", "_"): p})

  if len(result) != len(projectPaths):
    echo "there may be nonunique entries in the project names"

proc listTmuxSessions(): string =
  let (output, _) = execCmdEx("tmux list-sessions -F '#S'")
  return output

proc checkFzf() =
  if findExe("fzf") == "":
    echo "tsm requires fzf"
    quit 1

when isMainModule:
  checkFzf()

  let projects = findProjects()
  let selected = pickProject(projects)

  if existsEnv("TMUX"):
    if selected notin listTmuxSessions():
      discard execCmd(&"tmux new-session -d -s {selected} -c {projects[selected]}")
    discard execCmd(&"tmux switch-client -t {selected}")
  else:
    if selected notin listTmuxSessions():
      discard execCmd(&"tmux new-session -s {selected} -c {projects[selected]}")
    else:
      discard execCmd(&"tmux attach -t {selected}")
