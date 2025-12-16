import sigui/[uibase, textArea, animations]
import ./[colors, fonts, focus]


type LineEdit* = ref object of Uiobj
  text*: Property[string]
  placeholder*: Property[string]

  textArea*: TextArea
  border*: UiRectBorder

  valid*: Property[bool] = true.property
  # unedited*: Property[bool] = true.property
  
  # popupShowAlways*: Property[bool]
  # popup*: Uiobj


method init*(this: LineEdit) =
  procCall this.super.init()

  this.makeLayout:
    h = 9 + 14 + 9
    w = 100

    - UiRectBorder.new:
      this.fill(parent)
      root.border = this
      
      radius = 5
      borderWidth = 1
      color = binding:
        if root.valid[]:
          if textArea.active[]: color_border_accent_lineEdit
          else: color_border_lineEdit
        else:
          if textArea.active[]: color_border_accent_lineEdit_invalid
          else: color_border_lineEdit_invalid
      
      - this.color.transition(0.2's):
        easing = outSquareEasing
      

    - TextArea.new as textArea:
      this.fill(parent)
      root.textArea = this
    
      text = binding: root.text[]
      root.text[] = binding: this.text[]

      on this.active[] == true:
        if currentFocus[] != root:
          setFocus root
      
      on currentFocus[] == root:
        this.active[] = true

      + this.textArea:
        this.fill(this.parent, 10, 7)

      + this.textObj:
        font = font_default.withSize(14)

        color = binding:
          if textArea.active[]: color_fg_active
          else: color_fg
      
        - this.color.transition(0.2's):
          easing = outSquareEasing
    
        - UiText.new:
          centerY = parent.center

          font = font_default.withSize(14)
          text = binding: root.placeholder[]

          visibility = binding:
            if root.text[] == "": visible
            else: collapsed
      
          - this.color.transition(0.2's):
            easing = outSquareEasing

          color = binding:
            if textArea.active[]: color_fg_placeholder_active
            else: color_fg_placeholder
      
      + this.cursorObj[]: + this.UiRect:
        color = color_fg_active

