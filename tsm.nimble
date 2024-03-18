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
requires "https://github.com/inv2004/illwill/#6ba6045038a01d1855208c4a9be7d4826d774001"
# requires "illwill == 0.3.2",
requires "cligen"
requires "https://github.com/daylinmorgan/bbansi >= 0.1.0"

