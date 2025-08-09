import std/[os, sequtils, strformat, strutils, tables]
import usu
import term

type
  TsmConfig* = object
    paths*: seq[string]
    sessions*: seq[Session]

  Session = object
    name*, path*: string

var configPath = getEnv("TSM_CONFIG", getConfigDir() / "tsm" / "config.usu")

proc sessionNames*(tc: TsmConfig): seq[string] =
  tc.sessions.mapIt(it.name)

proc loadUsuFile(p: string): UsuNode =
  try:
      return parseUsu(readFile p)
  except:
      termQuit fmt("failed to load config file\npath: {configPath}\nmessage: ") & getCurrentExceptionMsg()



proc loadConfigFile(): TsmConfig =
  if fileExists(configPath):
    let usuNode = loadUsuFile(configPath)
    let topFields = usuNode.fields
    if "paths" in topFields:
      for p in usuNode.fields["paths"].elems:
        result.paths.add p.value.strip().expandTilde() # usu is adding a newline....
    if "sessions" in topFields:
      for session in usuNode.fields["sessions"].elems:
        result.sessions.add Session(
          # usu parser is leaving a newline at the end of first value in array?
          name: session.fields["name"].value.strip(),
          path: session.fields["path"].value.expandTilde()
        )



proc loadTsmConfig*(): TsmConfig =
  result = loadConfigFile()
  let tsmDirs = getEnv("TSM_PATHS")
  if tsmDirs != "":
    result.paths = tsmDirs.split(":")

when isMainModule:
  echo loadConfigFile()

