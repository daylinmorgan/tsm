import std/[os, sequtils, strformat, strutils, parsecfg, tables]
import term

type
  TsmConfig* = object
    paths*: seq[string]
    sessions*: seq[Session]

  Session = object
    name*, path*: string

var configPath = getEnv("TSM_CONFIG", getConfigDir() / "tsm" / "config.ini")

proc sessionNames*(tc: TsmConfig): seq[string] =
  tc.sessions.mapIt(it.name)

template check(cond: bool, msg: string) =
  if not cond:
    termQuit fmt"failed to load config file\npath: {configPath}\nmessage: " & msg

proc loadConfigFile(): TsmConfig =
  let dict = loadConfig(configPath)
  for k, v in dict.pairs:
    if k == "paths":
      for path, v2 in v.pairs:
        check v2 == "", fmt"unexpected value in [paths] section {v}"
        result.paths.add path
    else:
      check k.startsWith("session."), fmt"unexpected config section: {k}"
      let name = k.replace("session.")
      check v.hasKey("path"), fmt"expected value for path in section: {k}"
      let path = v["path"]
      result.sessions.add Session(name:name, path:path)

proc loadTsmConfig*(): TsmConfig =
  result = loadConfigFile()
  let tsmDirs = getEnv("TSM_PATHS")
  if tsmDirs != "":
    result.paths = tsmDirs.split(":")

when isMainModule:
  echo loadConfigFile()

