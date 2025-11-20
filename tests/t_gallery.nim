import pkg/sigui
import toscel


let win = newUiWindow(title="Toscel component library galery")


win.makeLayout:
  this.clearColor = "202020".color

  - Layout.col:
    this.centerIn parent
    gap = 10

    - Layout.row:
      gap = 10

      - Button.new:
        text = "Button"

      - LineEdit.new:
        text = "LineEdit"


run win

