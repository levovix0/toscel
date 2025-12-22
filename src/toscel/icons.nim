import std/[os, strutils, tables, macros]


type
  Icon* = ref object
    svg*: string


const iconsPath* {.strdefine.} = currentSourcePath().parentDir.parentDir / "icons"
  ## path to all application's icons
  ## can be changed by providing --define:\"iconsPath:path/to/your/icons\" in config.nims or in compilation flags
  ## note that toscel uses some icons for it's components,
  ## so provide them in your icon folder or copy them from the ~/.nimble/pkgs2/toscel-xxx/icons folder


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



proc getIcon*(name: string, orLoad: string = "", orUse: string = ""): Icon =
  let res = loadedIcons.mgetOrPut(name).addr

  if res[] == nil and orUse != "":
    res[] = Icon(svg: orUse)

  if res[] == nil and orLoad != "":
    res[] = loadIcon(orLoad)
  
  result = res[]


macro icon*(name: string, fromToscel: static bool = false): Icon =
  let staticIcon =
    if fileExists(iconsPath / (name.strVal & ".svg")):
      staticRead(iconsPath / (name.strVal & ".svg"))
    else:
      when not defined(toscel_allow_runtime_icons):
        if fromToscel:
          warning("unable to find file " & name.strVal & ".svg in iconsPath (" & iconsPath & "). This will mean the icon will be loaded at runtime from system icon theme and may not exist. Note that toscel uses some icons for it's components so provide them in your icon folder or copy them from the ~/.nimble/pkgs2/toscel-xxx/icons folder. This warning can be silenced with -d:toscel_allow_runtime_icons", name)
        else:
          warning("unable to find file " & name.strVal & ".svg in iconsPath (" & iconsPath & "). This will mean the icon will be loaded at runtime from system icon theme and may not exist. Note that you can change iconsPath by providing --define:\"iconsPath:path/to/your/icons\" in your config.nims or in compilation flags. This warning can be silenced with -d:toscel_allow_runtime_icons", name)
      ""

  result = nnkCall.newTree(
    ident("getIcon"),
    name,
    name,
    newLit(staticIcon)
  )





when isMainModule:
  proc main =
    echo "document-new".icon.svg

  main()

