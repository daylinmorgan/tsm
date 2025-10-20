import std/[strutils]
import hwylterm
export hwylterm

const
  sep = bb" [magenta]|[/] "
  prefix = bb"[cyan]tsm[/]" & sep
  errPrefix = prefix & bb"[red]error[/]" & sep

let
  errPrefixLen = bb(errPrefix).len
  prefixLen = bb(prefix).len

proc indentForPrefix(s: string, length: Natural): string =
  if "\n" notin s: return s
  let lines = s.splitLines()
  result.add lines[0]
  result.add "\n"
  for i, l in lines[1..^1]:
    result.add " ".repeat(length)
    result.add l
    if i != lines.len - 2:
      result.add "\n"

proc termEcho*(x: varargs[string, `$`]) =
  hecho prefix, x.join(" ").indentForPrefix(prefixLen)

proc termError*(x: varargs[string, `$`]) =
  hecho errPrefix, x.join(" ").indentForPrefix(errPrefixLen)

proc termQuit*(x: varargs[string, `$`]) =
  termError x
  quit QuitFailure

