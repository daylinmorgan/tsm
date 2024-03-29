import std/[strformat, strutils]


task debugTui, "debug tui":
  exec "nim -d:debug c -r src/tui.nim"

task build, "build app":
  selfExec "c -o:bin/tsm src/tsm.nim"

task buildRelease, "build app":
  selfExec "c -d:release -o:bin/tsm src/tsm.nim"

task release, "build release assets":
  version = (gorgeEx "git describe --tags --always --match 'v*'").output
  exec &"forge release -v {version} -V"

task updateNixLock, "regenerate nix/lock.json":
  exec "nix run github:daylinmorgan/nnl nimble.lock > nix/lock.json"

task bundle, "package build assets":
  withDir "dist":
    for dir in listDirs("."):
      echo dir
      let cmd = if "windows" in dir:
        &"7z a {dir}.zip {dir}"
      else:
        &"tar czf {dir}.tar.gz {dir}"
      cpFile("../README.md", &"{dir}/README.md")
      exec cmd



# begin Nimble config (version 2)
--noNimblePath
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
