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
          selectedOption = 0


      - Layout.row:
        align = center
        gap = 10

        - Button.new:
          enabled = false
          text = "Button (disabled)"
  

  - PaletteArea.new:
    this.fill(parent)

    - Palette.new:
      text = "Explorer"
      icon = "format-text-direction-ltr".icon
      
      + this.content:
        fill = "#202020".color
        w = 300
        h = 200
        y = 40
        x = 40
        
        - Layout.col:
          this.fill(parent, padding_default_horizontal, padding_default_vertical)
          - Label.new:
            text = "file1.ext (todo: actual file exporer)"
          
          - Label.new:
            text = "file2.ext"

    - Palette.new:
      text = "Icons"
      icon = "smiley-add".icon
      iconSize = 14  # anything bigger that 14 breaks at loadTexture
      iconTextLayout = IconTextVertical
      jointSide = Left
      
      + this.content:
        w = 200
        h = 200
        x = 100
        y = 300

        - Layout.row:
          top = parent.top + padding_default_vertical
          centerX = parent.center
          wrap = true
          lengthBeforeWrap = binding: parent.w[] - 20
          gap = 10

          - Label.new:
            text = "todo: icon1"
          
          - Label.new:
            text = "todo: icon2"
          
          - Label.new:
            text = "todo: icon3"



run win

