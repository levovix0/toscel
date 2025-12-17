import pkg/sigui/[uibase]
import ./[colors, label]

type
  Panel* = ref object of Uiobj
    header*: Property[string]

    headerObj* {.cursor.}: Uiobj
    background* {.cursor.}: UiRect
    border* {.cursor.}: UiRect
    content* {.cursor.}: Uiobj

registerComponent Panel


# todo: newChildsObject as a typed proc that makeLayout calls?


proc left*(this: Panel, margin: float32 = 0): Anchor =
  this.Uiobj.left(margin + padding_panel_horizontal)

proc right*(this: Panel, margin: float32 = 0): Anchor =
  this.Uiobj.right(margin - padding_panel_horizontal)

proc top*(this: Panel, margin: float32 = 0): Anchor =
  this.headerObj.bottom(margin + padding_panel_vertical)

proc bottom*(this: Panel, margin: float32 = 0): Anchor =
  this.Uiobj.bottom(margin - padding_panel_vertical)

proc center*(this: Panel, margin: float32 = 0): Anchor =
  this.content.center(margin)


method init*(this: Panel) =
  procCall this.super.init()

  this.makeLayout:
    w = 200
    h = padding_default_vertical * 3 + fontSize_default

    - UiRect.new as root.border:
      this.fill parent.Uiobj
      
      radius = 5
      color = color_border_panel

    - UiRect.new as root.background:
      this.fill parent.Uiobj, 1

      radius = 4
      color = color_bg

    - Uiobj.new as root.headerObj:
      this.fillHorizontal(parent.Uiobj)
      h = binding:
        if root.header[] == "": 0
        else: padding_default_vertical * 3 + fontSize_default
      
      - Label.new:
        this.centerIn(parent)
        text = binding: root.header[]
    
    - Uiobj.new as root.content:
      this.fill(parent.Uiobj, padding_panel_horizontal, padding_panel_vertical)
      this.top = root.headerObj.bottom

  this.newChildsObject = this.content


