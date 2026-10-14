import std/[os, sequtils, algorithm]
import pkg/[sigui]
import toscel


let win = newUiWindow(title="Toscel component library galery")


win.makeLayout:
  this.clearColor = "202020".color


  - Panel(header = "Panel", centerIn(parent)):
    - Layout(col(), align = center, gap = 10):
      parent.w[] = binding: this.w[] + parent.content.x[] + parent.content.margin.bottom
      parent.h[] = binding: this.h[] + parent.content.y[] + parent.content.margin.bottom

      - Layout(row(), align = center, gap = 10):
        - Label(text = "Label")
        - Button(text = "Button")
        - LineEdit(text = "LineEdit")
        - ComboBox(options = @["ComboBox", "with", "text", "options"], selectedOption = 0)

      - Layout(row(), align = center, gap = 10):
        - Button(text = "Button (disabled)", enabled = false)
  

  - PaletteArea():
    this.fill(parent)

    - Palette(text = "Explorer", icon = "format-text-direction-ltr".icon):
      + this.content:
        fill = "#202020".color
        w = 300
        h = 150
        y = 40
        x = 40

        - ScrollArea(fill(parent)):
          - Layout(col(), x = 10, gap = 10):
            for x in walkDir(getCurrentDir(), relative = true).toSeq.sorted:
              - Label(text = if x.kind == pcDir: x.path & "/" else: x.path)

    - Palette(text = "Icons", icon = "smiley-add".icon):
      iconSize = 14  # anything bigger that 14 breaks at loadTexture
      iconTextLayout = IconTextVertical
      jointSide = Left
      
      + this.content:
        w = 200
        h = 200
        x = 100
        y = 300

        - Layout(row(), gap = 10, wrap = true):
          top = parent.top + padding_default_vertical
          centerX = parent.center
          lengthBeforeWrap = binding: parent.w[] - 20

          - Label(text = "todo: icon1")
          - Label(text = "todo: icon2")
          - Label(text = "todo: icon3")


when defined(inspector): openInspector win
run win

