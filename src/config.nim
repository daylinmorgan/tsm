import std/[os, parsecfg, sequtils, tables, strutils]

import term

type
  TsmConfig* = object
    dirs*: seq[string]
    sessions*: seq[Session]

  Session = object
    name*, dir*: string

proc loadConfigFile(): TsmConfig =
  let configPath = getHomeDir() / ".config/tsm/config.ini"
  if configPath.fileExists():
    let iniTable = loadConfig(configPath)
    if "sessions" in iniTable:
      for key, value in iniTable["sessions"].pairs:
        result.sessions.add Session(name: key, dir: value)
    if "dirs" in iniTable:
      for key, value in iniTable["dirs"].pairs:
        if value != "":
          termError "[dirs] table should only contain a list of paths"
        result.dirs.add key

proc loadTsmConfig*(): TsmConfig =
  result = loadConfigFile()
  let tsmDirs = getEnv("TSM_DIRS")
  if tsmDirs != "":
    result.dirs = tsmDirs.split(":")

when isMainModule:
  let dict = loadConfig(getHomeDir() / ".config/tsm/config.ini")
  let sections = dict.sections().toSeq()
  if "sessions" in sections:
    for key, value in dict["sessions"].pairs:
      echo key, value

  echo loadTsmConfig()
