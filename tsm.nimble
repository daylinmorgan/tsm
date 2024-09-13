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
requires "cligen"
requires "https://github.com/daylinmorgan/bbansi >= 0.1.1"
requires "yaml"

