import std/[strformat, strutils]


task debugSelect, "debug select":
  exec "nim -d:debugSelect c -r src/selector.nim"

task build, "build app":
  selfExec "c -o:bin/tsm src/tsm.nim"

task buildRelease, "build release app":
  selfExec "c -d:release -o:bin/tsm src/tsm.nim"

task release, "build release assets w/forge":
  version = (gorgeEx "git describe --tags --always --match 'v*'").output
  exec &"forge release -v {version} -V"

task bundle, "package forge build assets":
  withDir "dist":
    for dir in listDirs("."):
      echo dir
      let cmd =
        if "windows" in dir: &"7z a {dir}.zip {dir}"
        else: &"tar czf {dir}.tar.gz {dir}"
      cpFile("../README.md", &"{dir}/README.md")
      exec cmd


# begin Nimble config (version 2)
--noNimblePath
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
