# Package

version       = "2025.1003"
author        = "Daylin Morgan"
description   = "tmux session manager"
license       = "MIT"
srcDir        = "src"
bin           = @["tsm"]
binDir        = "bin"

# Dependencies

requires "nim >= 2.0.0"
requires "https://github.com/daylinmorgan/hwylterm"
requires "https://github.com/usu-dev/usu-nim"

