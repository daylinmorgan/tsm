import std/[os, strformat, strutils]
import usu
import ./term


type
  Root* = object
    path*: string
    depth*: Natural

  Config* = object
    roots*: seq[Root]
    sessions*: seq[Session]

  Window* = object
    name*: string
    exec*: string

  Session = object
    name*: string
    path*: string
    windows*: seq[Window]

func init(_: typedesc[Root], path: string): Root =
  result.path = path.strip().expandTilde()

proc fromUsu(target: var seq[Root], u: UsuNode) =
  checkKind u, UsuArray
  for e in u.elems:
    checkKind e, {UsuMap, UsuValue}
    case e.kind
    of UsuMap:
      var root: Root
      fromUsu(root, e)
      target.add root
    of UsuValue:
      var path: string
      fromUsu(path, e)
      target.add Root.init(path)
    else: assert false

var configPath = getEnv("TSM_CONFIG", getConfigDir() / "tsm" / "config.usu")

proc sessionNames*(c: Config): seq[string] =
  for s in c.sessions:
    result.add s.name

proc loadConfigFile(): Config =
  try:
    return parseUsu(readFile configPath).to(type(result))
  except:
    termQuit fmt("failed to load config file\npath: {configPath}\nmessage: ") & getCurrentExceptionMsg()

func finalize(r: Root): Root =
  result = r
  result.path = r.path.strip().expandTilde()

func finalize(s: Session): Session =
  result.name = s.name.strip()
  result.path = s.path.expandTilde()
  result.windows = s.windows

proc finalize*(c: Config): Config =
  for r in c.roots:
    result.roots.add r.finalize()

  for session in c.sessions:
    let s = session.finalize()
    if not dirExists s.path:
      termError bb(
        fmt("ignoring session: [yellow]{s.name}[/]\n") &
        fmt"path: [b]{s.path}[/] does not exist"
      )
      continue
    result.sessions.add s

proc tsmDirsToRoots(s: string): seq[Root] =
  for p in s.split(":"):
    result.add Root.init(p)

proc loadTsmConfig*(): Config =
  if fileExists(configPath):
    result = loadConfigFile()
  let tsmDirs = getEnv("TSM_PATHS")
  if tsmDirs != "":
    result.roots = tsmDirsToRoots(tsmDirs)
  result = result.finalize()

when isMainModule:
  echo loadTsmConfig()
