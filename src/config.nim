import std/[os, sequtils, streams, strformat, strutils]
import yaml
import term

type
  TsmConfig* = object
    dirs*: seq[string]
    sessions*: seq[Session]

  Session = object
    name*, dir*: string

proc sessionNames*(tc: TsmConfig): seq[string] =
  tc.sessions.mapIt(it.name)

proc loadConfigFile(): TsmConfig =
  let configPath = getEnv("TSM_CONFIG", getConfigDir() / "tsm" / "config.yml")
  try:
    var s = newFileStream(configPath)
    load(s, result)
    s.close()
  except:
    termError fmt(
      "failed to load config file\npath: {configPath}\nmessage: {getCurrentExceptionMsg()}"
    )

proc loadTsmConfig*(): TsmConfig =
  result = loadConfigFile()
  let tsmDirs = getEnv("TSM_DIRS")
  if tsmDirs != "":
    result.dirs = tsmDirs.split(":")

when isMainModule:
  echo loadConfigFile()
