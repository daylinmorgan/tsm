# Package

version       = "2024.1001"
author        = "Daylin Morgan"
description   = "tmux session manager"
license       = "MIT"
srcDir        = "src"
bin           = @["tsm"]
binDir        = "bin"

# Dependencies

requires "nim >= 2.0.0"
# illwill PR 47
requires "https://github.com/inv2004/illwill/#449ae5d2f05aba125d5a71823ff1da55b1766d70"
# requires "illwill == 0.3.2",
requires "cligen"
requires "https://github.com/daylinmorgan/bbansi >= 0.1.0"
requires "https://github.com/usu-dev/usu-nim"

