import sigui/[uibase, textArea]
import ./[colors, fonts, focus]


type
  ThemedUiText* = ref object of UiText
    ## UiText that follows toscel theme

  Label* = ref object of Uiobj
    text*: Property[string]
    color*: Property[Color] = color_fg.property
    fontSize*: Property[float32] = 14'f32.property
    font*: Property[Typeface]

    textArea*: TextArea

    fitTextBinding*: EventHandler

    # popup*: Uiobj

registerComponent ThemedUiText
registerComponent Label


method init*(this: ThemedUiText) =
  procCall this.super.init()
  
  this.color[] = color_fg
  this.font[] = font_default.withSize(14)


method init*(this: Label) =
  procCall this.super.init()

  this.makeLayout:
    font = font_default

    - TextArea.new as textArea:
      this.fill(parent)
      root.textArea = this

      root.w[] = binding(root.fitTextBinding): this.textObj.w[] + 2
      root.h[] = binding(root.fitTextBinding): this.textObj.h[]

      this.allowedInteractions.excl textInput
    
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


proc unselectable*(t: typedesc[Label]): ThemedUiText = new ThemedUiText
proc themed*(t: typedesc[UiText]): ThemedUiText = new ThemedUiText

