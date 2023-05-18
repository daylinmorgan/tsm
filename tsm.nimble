# Package

version       = "23.5.1"
author        = "Daylin Morgan"
description   = "tmux session manager"
license       = "MIT"
srcDir        = "src"
bin           = @["tsm"]

# Dependencies

requires "nim >= 1.6.12",
         "cligen"
