# Package

version       = "2023.1001"
author        = "Daylin Morgan"
description   = "tmux session manager"
license       = "MIT"
srcDir        = "src"
bin           = @["tsm"]
binDir        = "bin"

# Dependencies

requires "nim >= 1.6.12",
         "illwill",
         "cligen"

taskRequires "release", "https://github.com/daylinmorgan/ccnz"

import strformat
const targets = [
    "x86_64-linux-gnu",
    "x86_64-linux-musl",
    "x86_64-macos-none",
    # "x86_64-windows-gnu" # no tsm on windows
  ]

task release, "build release assets":
  mkdir "dist"
  for target in targets:
    let
      ext = if target == "x86_64-windows-gnu": ".cmd" else: ""
      outdir = &"dist/{target}/"
      app = projectName()
    exec &"ccnz cc --target {target} --nimble -- --out:{outdir}{app}{ext} -d:release src/{app}"

task bundle, "package build assets":
  cd "dist"
  for target in targets:
    let
      app = projectName()
      cmd =
        if target == "x86_64-windows-gnu":
          &"7z a {app}-v{version}-{target}.zip {target}"
        else:
          &"tar czf {app}-v{version}-{target}.tar.gz {target}"

    cpFile("../README.md", &"{target}/README.md")
    exec cmd



