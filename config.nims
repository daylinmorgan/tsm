import std/[strformat, strutils]


task debugTui, "debug tui":
  exec "nim -d:debug c -r src/tui.nim"

task build, "build app":
  selfExec "c -o:bin/tsm src/tsm.nim"

task release, "build release assets":
  version = (gorgeEx "git describe --tags --always --match 'v*'").output
  exec &"forge release -v {version} -V"

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


