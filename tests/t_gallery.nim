import pkg/sigui
import toscel


let win = newUiWindow(title="Toscel component library galery")


win.makeLayout:
  this.clearColor = "202020".color

  - Layout.col:
    this.centerIn parent
    align = center
    gap = 10

    - Layout.row:
      align = center
      gap = 10

      - Label.new:
        text = "Label"

      - Button.new:
        text = "Button"

      - LineEdit.new:
        text = "LineEdit"


run win

