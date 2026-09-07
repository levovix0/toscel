import std/[strutils, os]
import pkg/pixie/[fonts]


iterator systemFonts*(): string =
  when defined(windows):
    for path in walkDirRec("C:/Windows/Fonts"):
      if path.splitFile.ext == ".ttf":
        yield path
  else:
    if dirExists(gethomedir()/".local/share/fonts"):
      for path in walkDirRec(gethomedir()/".local/share/fonts"):
        if path.splitFile.ext == ".ttf":
          yield path
    for path in walkDirRec("/usr/share/fonts"):
      if path.splitFile.ext == ".ttf":
        yield path


const defaultSystemFonts* = @["roboto", "ubuntu", "notosans", "arial", "adwaitasans"]

proc findSystemFont*(query: seq[string] = defaultSystemFonts): Typeface =
  ## todo: load each font (that is loadable), add them as typeface.fallbacks
  for queryEntry in query:
    for path in systemFonts():
      var name = path.splitFile.name.normalize
      name.removeSuffix "-regular"
      if cmpIgnoreStyle(name, queryEntry) == 0:
        return readTypeface(path)
  
  return nil



var font_default*: Typeface

when not defined(toscel_override_font_default):
  font_default = findSystemFont()
  
  if font_default == nil:
    for path in systemFonts():
      font_default = readTypeface(path)
      break

