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
requires "illwill >= 0.4.1"
requires "https://github.com/daylinmorgan/hwylterm#cbeefd67"
requires "https://github.com/usu-dev/usu-nim"

