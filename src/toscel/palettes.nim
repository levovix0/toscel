## not to be confused with colors, palettes are movable and resizable panels

import pkg/sigui/[uibase, layouts, mouseArea]
import ./[colors, icons, fonts]

type
  IconTextLayout* = enum
    IconText
    TextIcon
    TextOnly
    IconOnly
    IconTextVertical
    TextIconVertical
  

  JointSide* = enum
    Top
    Bottom
    Left
    Right


  Palette* = ref object of Uiobj
    ## rect of the Palette determines current visible dimensions of palette title (tab)
    ## Palette always joins PaletteContent content at one of it's side, always inside PaletteArea, and is always outside of PaletteContent
    text*: /string
    icon*: /Icon
    iconTextLayout*: /IconTextLayout

    fontSize*: /float32 = /14'f32
    iconSize*: /float32 = /14'f32
    font*: /Typeface

    content*: PaletteContent
    jointSide*: /JointSide

    titleSize*: /Vec2
      ## size that the palette title (tab) takes, including padding.
      ## set automatically, used to limit content resizing (see minWidth, minHeight)

    # group* {.cursor.}: PaletteGroup
    area* {.cursor.}: PaletteArea
    mouse* {.cursor.}: MouseArea

  PaletteContent* = ref object of Uiobj
    ## rect of the PaletteContent can be set to determine the default position and size of it.
    fill*: /Color = /color_bg
    stroke*: /Color = /color_border_panel
    minSize*: /Vec2  # todo: every sigui widget should be able to have min and max size for itself

    palette* {.cursor.}: Palette


  # PaletteGroup* = ref object
  #   ## groups the tabs of Palettes
  #   palettes*: seq[Palette]
  #   tabContainer*: Uiobj

  PaletteArea* = ref object of Uiobj
    ## rect of the PalleteArea determines the area in which this palette can be freely placed
    palettes*: seq[Palette]
    # groups*: seq[PaletteGroup]


registerComponent Palette
registerComponent PaletteArea
registerComponent PaletteContent

# todo:
#[
proc size(layout: TextIconLayout, text: string, font: Font, icon: DrawContextImage): Vec2

registerComponent Palette:
  bindings:
    this.fontFace = binding:
      this.font[].withSize(this.fontSize[])

    this.iconTexture = binding:
      if this.icon[] != nil:
        this.root.ctx.parseSvg(this.iconSize[].vec2.ivec2, this.icon[].svg)
      else:
        nil
    
    this.wh = binding:
      size(this.textIconLayout[], this.text[], @(this.fontFace), @(this.iconTexture))
]#



proc incl[T: ref object](arr: var seq[T], obj: T) =
  if arr.find(obj) == -1:
    arr.add obj

proc excl[T: ref object](arr: var seq[T], obj: T) =
  if (let i = arr.find(obj); i != -1):
    arr.delete i


proc findParent*(this: Uiobj, typ: typedesc): typ =
  # todo: move to sigui
  result = nil
  var obj = this
  while obj != nil:
    if obj of typ: return obj.typ
    obj = obj.parent



# proc jointSide(this: Uiobj, target: Uiobj): JointSide =
#   let a = this.globalXy
#   let b = target.globalXy

#   if b.y < a.y - 1e-6:
#     Top
#   elif b.x < a.x - 1e-6:
#     Left
#   elif b.y + target.h[] > a.y + this.h[] + 1e-6:
#     Bottom
#   elif b.x + target.w[] > a.x + this.w[] + 1e-6:
#     Right
#   else:
#     Top

proc invert*(x: JointSide): JointSide =
  case x
  of Left: Right
  of Right: Left
  of Top: Bottom
  of Bottom: Top


proc xy(size: Vec2, target: Uiobj, jointSide: JointSide): Vec2 =
  case jointSide
  of Left:   target.globalXy - vec2(size.x, 0)
  of Right:  target.globalXy + vec2(target.w[], 0)
  of Top:    target.globalXy - vec2(0, size.y)
  of Bottom: target.globalXy + vec2(0, target.h[])


proc raiseToTop*(this: Palette) =
  ## raises palette and it's content to the topmost layer of the PaletteArea
  this.layer = this.area.after
  this.content.layer = this.area.after


proc minWidth*(this: Palette): float32 =
  ## min width that palette content can take with current jointSide
  ## (the axis with title joined to it can't be smaller than title, other axis can shrink to 0)
  this.content.minSize[].x + (if this.jointSide[] in {Top, Bottom}: this.titleSize[].x else: 0'f32)

proc minHeight*(this: Palette): float32 =
  ## min height that palette content can take with current jointSide
  ## (the axis with title joined to it can't be smaller than title, other axis can shrink to 0)
  this.content.minSize[].y + (if this.jointSide[] in {Top, Bottom}: 0'f32 else: this.titleSize[].y)



method init*(this: Palette) =
  procCall this.super.init()

  this.area = this.findParent(PaletteArea)
  doAssert this.area != nil, "Palette must have a PaletteArea parent"
  this.area.palettes.incl this
  this.deleted.connectTo this.area:
    delete this.content
    this.area.palettes.excl this

  let palette = this

  this.area.makeLayout:
    - PaletteContent(palette: palette) as palette.content

  this.makeLayout:
    font = font_default
    
    this.xy = binding:
      discard (this.w[], this.h[], this.content.x[], this.content.y[], this.content.w[], this.content.h[])
      xy(this.wh, this.content, this.jointSide[]).posToLocal(this.parent)

    template dragger(this: MouseArea, pSize, pPos, delta, minSize) =
      const hasPos = astToStr(pPos) != "{none}"
      const hasMinSize = astToStr(minSize) != "{none}"

      var sizeOnPress: typeof(pSize)
      when hasPos:
        var posOnPress: typeof(pPos)

      this.pressed.changed.connectTo this:
        if this.pressed[]:
          root.raiseToTop()

      this.grabbed.changed.connectTo this:
        if this.grabbed[]:
          sizeOnPress = pSize
          when hasPos: posOnPress = pPos

      this.moved.changed.connectTo this:
        if this.pressed[]:
          let d {.inject.} = (this.root.mouseState.pos - this.pressWindowPos)
          let deltaSize = (when hasMinSize: max(sizeOnPress + delta, minSize) else: sizeOnPress + delta) - sizeOnPress
          pSize = sizeOnPress + deltaSize
          when hasPos: pPos = posOnPress - deltaSize

    - MouseArea(fill parent, dragger(root.content.globalXy, {none}, d, {none})) as root.mouse

    # side resize w/h (also x/y on the min side)
    - MouseArea(layer = after root.content):
      w = 5
      centerX = root.content.right
      top = parent.top
      bottom = root.content.bottom
      cursor = (ref Cursor)(kind: builtin, builtin: sizeHorizontal)
      this.dragger(root.content.w[], {none}, d.x, root.minWidth())

    - MouseArea(layer = after root.content):
      h = 5
      centerY = root.content.bottom
      left = parent.left
      right = root.content.right
      cursor = (ref Cursor)(kind: builtin, builtin: sizeVertical)
      this.dragger(root.content.h[], {none}, d.y, root.minHeight())

    - MouseArea(layer = after root.content):
      w = 5
      centerX = root.left
      top = parent.top
      bottom = root.content.bottom
      cursor = (ref Cursor)(kind: builtin, builtin: sizeHorizontal)
      this.dragger(root.content.w[], root.content.x[], -d.x, root.minWidth())

    - MouseArea(layer = after root.content):
      h = 5
      centerY = root.top
      left = parent.left
      right = root.content.right
      cursor = (ref Cursor)(kind: builtin, builtin: sizeVertical)
      this.dragger(root.content.h[], root.content.y[], -d.y, root.minHeight())

    # corners resize w+h at once (also x/y on the min side)
    - MouseArea(layer = after root.content):
      w = 10
      h = 10
      centerX = root.content.right
      centerY = root.content.bottom
      cursor = (ref Cursor)(kind: builtin, builtin: sizeBottomRight)
      this.dragger(root.content.w[], {none}, d.x, root.minWidth())
      this.dragger(root.content.h[], {none}, d.y, root.minHeight())

    - MouseArea(layer = after root.content):
      w = 10
      h = 10
      centerX = root.left
      centerY = root.content.bottom
      cursor = (ref Cursor)(kind: builtin, builtin: sizeBottomLeft)
      this.dragger(root.content.w[], root.content.x[], -d.x, root.minWidth())
      this.dragger(root.content.h[], {none}, d.y, root.minHeight())

    - MouseArea(layer = after root.content):
      w = 10
      h = 10
      centerX = root.content.right
      centerY = root.top
      cursor = (ref Cursor)(kind: builtin, builtin: sizeTopRight)
      this.dragger(root.content.w[], {none}, d.x, root.minWidth())
      this.dragger(root.content.h[], root.content.y[], -d.y, root.minHeight())

    - MouseArea(layer = after root.content):
      w = 10
      h = 10
      centerX = root.left
      centerY = root.top
      cursor = (ref Cursor)(kind: builtin, builtin: sizeTopLeft)
      this.dragger(root.content.w[], root.content.x[], -d.x, root.minWidth())
      this.dragger(root.content.h[], root.content.y[], -d.y, root.minHeight())

    --- Layout():
      <--- {update}: root.iconTextLayout[]

      if root.iconTextLayout[] in {TextIconVertical, IconTextVertical}:
        this.col(spacing_default_vertical)
      else:
        this.row(spacing_default_horizontal)
      
      binding:
        if root.jointSide[] in {Top, Bottom}:
          this.centerX = Anchor()
          this.top = Anchor()
          this.centerY = parent.center
          this.left = parent.left + padding_default_horizontal
        else:
          this.centerY = Anchor()
          this.left = Anchor()
          this.centerX = parent.center
          this.top = parent.top + padding_default_vertical

      align = center

      if root.iconTextLayout[] != IconOnly:
        - UiText(color = color_fg):
          font = binding: root.font[].withSize(root.fontSize[])
          text = binding: root.text[]

      if root.iconTextLayout[] != TextOnly:
        - UiSvgImage(color = color_fg):
          image = binding:
            if root.icon[] != nil: root.icon[].svg
            else: ""
          this.wh = binding:
            let size = this.imageWh[].vec2
            if size.y == 0: vec2()
            else: size * (root.iconSize[] / size.y)
      
      if root.iconTextLayout[] in {IconText, IconTextVertical}:
        swap this.childs[^2], this.childs[^1]

      parent.wh = binding:
        var size = vec2(this.w[] + padding_default_horizontal*2, this.h[] + padding_default_vertical*2)
        if root.jointSide[] in {Top, Bottom}:
          size.x = max(size.x, root.content.w[])
        else:
          size.y = max(size.y, root.content.h[])
        size

      parent.titleSize[] = binding:
        vec2(this.w[] + padding_default_horizontal*2, this.h[] + padding_default_vertical*2)




method drawInner*(this: Palette, ctx: DrawContext) =
  ctx.fillRect(rect(this.globalXy, this.wh), this.content.fill[])

  let jointSide = this.jointSide[].invert
  if jointSide != Top:    ctx.fillRect(rect(this.globalXy, vec2(this.w[], 1)), this.content.stroke[])
  if jointSide != Bottom: ctx.fillRect(rect(this.globalXy + vec2(0, this.h[] - 1), vec2(this.w[], 1)), this.content.stroke[])
  if jointSide != Left:   ctx.fillRect(rect(this.globalXy, vec2(1, this.h[])), this.content.stroke[])
  if jointSide != Right:  ctx.fillRect(rect(this.globalXy + vec2(this.w[] - 1, 0), vec2(1, this.h[])), this.content.stroke[])



method recieve*(this: PaletteContent, signal: Signal) =
  ## raises the palette on mouse press and marks unhandled mouse events handled,
  ## so palettes below don't recieve clicks through this palette
  var pressInside = false
  signal.match MouseButtonEvent:
    if not signal.handled and e.pressed:
      pressInside = this.root.mouseState.pos.overlaps(this.globalRect)

  if pressInside: this.palette.raiseToTop()
  procCall this.super.recieve(signal)
  if pressInside: signal.WindowEvent.handled = true


method drawInner*(this: PaletteContent, ctx: DrawContext) =
  ctx.fillRect(rect(this.globalXy, this.wh), this.fill[])

  let jointSide = this.palette.jointSide[]
  if jointSide != Top:    ctx.fillRect(rect(this.globalXy, vec2(this.w[], 1)), this.stroke[])
  if jointSide != Bottom: ctx.fillRect(rect(this.globalXy + vec2(0, this.h[] - 1), vec2(this.w[], 1)), this.stroke[])
  if jointSide != Left:   ctx.fillRect(rect(this.globalXy, vec2(1, this.h[])), this.stroke[])
  if jointSide != Right:  ctx.fillRect(rect(this.globalXy + vec2(this.w[] - 1, 0), vec2(1, this.h[])), this.stroke[])
