# Package

version       = "2025.1002"
author        = "Daylin Morgan"
description   = "tmux session manager"
license       = "MIT"
srcDir        = "src"
bin           = @["tsm"]
binDir        = "bin"

# Dependencies

requires "nim >= 2.0.0"
requires "illwill >= 0.4.1"
requires "https://github.com/daylinmorgan/hwylterm#dbde9c91"
requires "https://github.com/usu-dev/usu-nim"

