import std/strutils
import hwylterm
export hwylterm

const
  sep = " [magenta]|[/] "
  prefix = "[cyan]tsm[/]" & sep
  errPrefix = prefix & "[red]error[/]" & sep

proc termEcho*(x: varargs[string, `$`]) =
  bbEcho prefix, x.join(" ")

proc termError*(x: varargs[string, `$`]) =
  bbEcho errPrefix, x.join(" ")

proc termQuit*(x: varargs[string, `$`]) =
  termError x
  quit QuitFailure
