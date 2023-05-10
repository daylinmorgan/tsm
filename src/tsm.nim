import std/[os, osproc, strformat, strutils, sugar, tables, tempfiles]


proc pickProject(projects: Table[string, string]): string =
  ## use fzf as a selector for the project
  let (inputFile, inPath) = createTempFile("tsm", "")
  let (outFile, outPath) = createTempFile("tsm", "")

  inputFile.write collect(for k in projects.keys(): k).join("\n")
  close inputFile

  let errCode = execCmd("fzf < " & inPath & " > " & outPath)
  close outFile

  removeFile(inPath)
  removeFile(outPath)

  if errCode != 0: echo &"fzf exited with code: {errCode}"

  result = readFile(outPath)
  result.stripLineEnd()

proc findProjects(): Table[string, string] =
  ## get a table of possible project paths

  var projectPaths: seq[string]
  for devDir in getEnv("TSM_DIRS").split(":"):
    echo devDir
    for d in walkDir(devDir):
      projectPaths.add d.path

  result = collect(for p in projectPaths: {splitPath(p)[1].replace(".", "_"): p})

  if len(result) != len(projectPaths):
    echo "there may be nonunique entries in the project names"

proc listTmuxSessions(): string =
  let (output, code) = execCmdEx("tmux list-sessions -F '#S'")
  if code != 0: echo &"error checking tmux sessions\nexit code:{code}\n{output}"
  return output

when isMainModule:
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

