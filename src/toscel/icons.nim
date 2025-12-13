import std/[os, strutils, tables]


type
  Icon* = ref object
    svg*: string



iterator systemIcons*(): string =
  when defined(windows):
    return
  else:
    # if dirExists("~/.local/share/icons/breeze-dark/actions/16/"):
    for path in walkDirRec("~/.local/share/icons/breeze-dark/actions/16/", {pcFile, pcLinkToFile}):
      if path.splitFile.ext == ".svg":
        yield path
    for path in walkDirRec("/usr/share/icons/breeze-dark/actions/16/", {pcFile, pcLinkToFile}):
      if path.splitFile.ext == ".svg":
        yield path


var loadedIcons: Table[string, Icon]


proc loadIcon*(name: string): Icon =
  for path in systemIcons():
    if path.splitFile.name.normalize == name.normalize:
      return Icon(svg: readFile path)



proc getIcon*(name: string, orLoad: string = ""): Icon =
  let res = loadedIcons.mgetOrPut(name).addr

  if res[] == nil and orLoad != "":
    res[] = loadIcon(orLoad)
  
  result = res[]



proc icon*(name: static): Icon =
  getIcon(name, name)


when isMainModule:
  proc main =
    echo "document-new".icon.svg

  main()

