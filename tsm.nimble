# Package

version       = "2023.1001"
author        = "Daylin Morgan"
description   = "tmux session manager"
license       = "MIT"
srcDir        = "src"
bin           = @["tsm"]
binDir        = "bin"

# Dependencies

requires "nim >= 2.0.0",
         "illwill",
         "cligen",
         "https://github.com/daylinmorgan/bbansi#main"

