import sigui/[uibase, textArea, animations]
import ./[colors, fonts]

type LineEdit* = ref object of Uiobj
  text*: Property[string]

  textArea*: TextArea


method init*(this: LineEdit) =
  procCall this.super.init()

  this.makeLayout:
    h = 9 + 14 + 9
    w = 100

    - UiRectBorder.new:
      this.fill(parent)
      
      radius = 5
      borderWidth = 1
      color = binding:
        if textArea.active[]: color_border_accent_button
        else: color_border_button
      
      - this.color.transition(0.2's):
        easing = outSquareEasing
      
    - TextArea.new as textArea:
      this.fill(parent, 10, 9)
      root.textArea = this

      + this.textObj[]:
        font = font_default.withSize(14)

        color = binding:
          if textArea.active[]: color_fg_active
          else: color_fg
      
        - this.color.transition(0.2's):
          easing = outSquareEasing
      
      + this.cursorObj[]: + this.UiRect:
        color = color_fg_active

    text = binding: this.textArea.text[]
    this.textArea.text[] = binding: root.text[]

