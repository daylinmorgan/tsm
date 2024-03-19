import std/[os, sequtils, tables, strutils]
import usu

import term

type
  TsmConfig* = object
    dirs*: seq[string]
    sessions*: seq[Session]

  Session = object
    name*, dir*: string

# TODO: update when the API for usu is complete
proc loadConfigFile(): TsmConfig =
  let configPath = getConfigDir() / "tsm" / "config.usu"
  if fileExists configPath:
    let usuNode = parseUsu(readFile configPath)
    let topFields = usuNode.fields
    if "dirs" in topFields:
      for dir in usuNode.fields["dirs"].elems:
        result.dirs.add dir.value
    if "sessions" in topFields:
      for session in usuNode.fields["sessions"].elems:
        result.sessions.add Session(name: session.fields["name"].value,
            dir: session.fields["dir"].value)

proc loadTsmConfig*(): TsmConfig =
  result = loadConfigFile()
  let tsmDirs = getEnv("TSM_DIRS")
  if tsmDirs != "":
    result.dirs = tsmDirs.split(":")

when isMainModule:
  echo loadConfigFile()

