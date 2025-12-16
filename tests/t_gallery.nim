import pkg/sigui
import toscel


let win = newUiWindow(title="Toscel component library galery")


win.makeLayout:
  this.clearColor = "202020".color


  - Panel.new:
    header = "Panel"
    this.centerIn(parent)

    - Layout.col:
      parent.w[] = binding: this.w[] + parent.content.x[] + parent.content.margin.bottom
      parent.h[] = binding: this.h[] + parent.content.y[] + parent.content.margin.bottom
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
        
        - ComboBox.new:
          options = @["ComboBox", "with", "text", "options"]


      - Layout.row:
        align = center
        gap = 10

        - Button.new:
          enabled = false
          text = "Button (disabled)"


run win

