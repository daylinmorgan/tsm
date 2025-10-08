import std/[os, strformat, strutils, tables]
import usu
import term
from usu/parser import UsuParserError, UsuNodeKind

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

template checkKind(node: UsuNode, k: UsuNodeKind) =
  if node.kind != k:
    raise newException(UsuParserError, "Expected node kind: " & $k & ", got: " & $node.kind & ", node: " & $node)

proc parseHook(s: var string, node: UsuNode) =
  checkKind node, UsuValue
  s = node.value

proc parseHook(s: var bool, node: UsuNode) =
  checkKind node, UsuValue
  s = parseBool(node.value)

proc parseHook[T](s: var seq[T], node: UsuNode) =
  checkKind node, UsuArray
  for n in node.elems:
    var e: T
    parseHook(e, n)
    s.add e

proc parseHook(o: var object, node: UsuNode) =
  checkKind node, UsuMap
  for name, value in o.fieldPairs:
    if name in node.fields:
      parseHook(value, node.fields[name])

proc to[T](node: UsuNode, t: typedesc[T]): T =
  parseHook(result, node)

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


