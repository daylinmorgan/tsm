import std/[os, strformat, strutils]
import usu
import ./term


type
  Config* = object
    paths*: seq[string]
    sessions*: seq[Session]

  Session = object
    name*, path*: string

var configPath = getEnv("TSM_CONFIG", getConfigDir() / "tsm" / "config.usu")

proc sessionNames*(c: Config): seq[string] =
  for s in c.sessions:
    result.add s.name

proc loadConfigFile(): Config =
  try:
    return parseUsu(readFile configPath).to(type(result))
  except:
    termQuit fmt("failed to load config file\npath: {configPath}\nmessage: ") & getCurrentExceptionMsg()


proc finalize*(c: Config): Config =
  for p in c.paths:
    result.paths.add p.strip().expandTilde()
  for session in c.sessions:
    let name = session.name.strip()
    let path = session.path.expandTilde()
    if not dirExists path:
      termError (
        fmt"ignoring session: [yellow]{name}[/]" &
        "\n" &
        fmt"path: [b]{path}[/] does not exist"
      )
      continue
    result.sessions.add Session(name: name, path: path)

proc loadTsmConfig*(): Config =
  if fileExists(configPath):
    result = loadConfigFile()
  let tsmDirs = getEnv("TSM_PATHS")
  if tsmDirs != "":
    result.paths = tsmDirs.split(":")

  result = result.finalize()

when isMainModule:
  echo loadConfigFile()
  echo loadTsmConfig()


