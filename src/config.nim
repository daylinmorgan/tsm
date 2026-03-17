import std/[os, strformat, strutils, sequtils]
import usu
import ./term


type
  Root* = object
    path*: string
    recursive*: bool
    depth*: Natural = 1

  Config* = object
    roots*: seq[Root]
    sessions*: seq[Session]

  Session = object
    name*, path*: string

func init(_: typedesc[Root], path: string): Root =
  result = Root()
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

proc finalize*(c: Config): Config =
  for r in c.roots:
    result.roots.add r.finalize()

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
  echo parseUsu("""
.roots [
   ~/dev/github/daylinmorgan/
   ~/dev/git.dayl.in/
   {.path ~/dev/github/usu-dev/ .recursive true}
   ~/dev/github/forks/
]

.sessions [
  { .name oizys    .path ~/oizys                 }
  { .name nimpkgs  .path ~/dev/github/nimpkgs    }
]
""").to(Config)



