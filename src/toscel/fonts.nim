import std/[strutils, os]
import pkg/pixie/[fonts]


iterator systemFonts*(): string =
  when defined(windows):
    for path in walkDirRec("~/.local/share/fonts"):
      if path.splitFile.ext == ".ttf":
        yield path
  else:
    if dirExists("~/.local/share/fonts"):
      for path in walkDirRec("~/.local/share/fonts"):
        if path.splitFile.ext == ".ttf":
          yield path
    for path in walkDirRec("/usr/share/fonts"):
      if path.splitFile.ext == ".ttf":
        yield path



proc findSystemFont*(query: seq[string] = @["roboto", "ubuntu", "notosans", "arial"]): Typeface =
  for queryEntry in query:
    for path in systemFonts():
      var name = path.splitFile.name.normalize
      name.removeSuffix "-regular"
      if cmpIgnoreStyle(name, queryEntry) == 0:
        return parseTtf(path.readFile)
  
  return nil



var font_default*: Typeface

when not defined(toscel_override_font_default):
  font_default = findSystemFont()

  if font_default == nil:
    for path in systemFonts():
      font_default = parseTtf(path.readFile)
      break

