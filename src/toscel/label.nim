import sigui/[uibase, textArea]
import ./[colors, fonts, focus]


type Label* = ref object of Uiobj
  text*: Property[string]
  color*: Property[Color] = color_fg.property
  fontSize*: Property[float32] = 14'f32.property
  font*: Property[Typeface]

  textArea*: TextArea

  fitTextBinding*: EventHandler

  # popup*: Uiobj


method init*(this: Label) =
  procCall this.super.init()

  this.makeLayout:
    font = font_default

    - TextArea.new as textArea:
      this.fill(parent)
      root.textArea = this

      this.textObj.w.changed.connectTo root.fitTextBinding:
        root.w[] = this.textObj.w[] + 2

      this.textObj.h.changed.connectTo root.fitTextBinding:
        root.h[] = this.textObj.h[]

      this.allowedInteractions = this.allowedInteractions - {textInput}
    
      text = binding: root.text[]

      on this.active[] == true:
        if currentFocus[] != root:
          setFocus root
      
      on currentFocus[] == root:
        this.active[] = true

      + this.textObj:
        font = binding: root.font[].withSize(root.fontSize[])

        color = binding: root.color[]
      
      + this.cursorObj[].UiRect:
        color = color_fg_active

