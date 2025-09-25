import pkg/sigui/[uibase, mouseArea, animations]
import siwin
import ./[icons, fonts, focus, colors]

type
  Button* = ref object of MouseArea
    icon*: Property[Icon]
    accent*: Property[bool]
    
    m_background: UiRect
    m_svgImage: UiSvgImage
    m_text: UiText

proc firstHandHandler_hook*(this: Button, name: static string, origType: typedesc)

registerComponent Button


proc clicked*(this: Button): var Event[void] =
  this.mouseDownAndUpInside

proc activated*(this: Button): var Event[void] =
  this.mouseDownAndUpInside


proc text*(this: Button): var Property[string] =
  this.m_text.text


proc adjustSize(this: Button) =
  let minW = 10 + (if this.icon != nil: this.m_text.h[] + 10 else: 0) + this.m_text.w[] + 10
  if this.w[] < minW: this.w[] = minW
  this.h[] = 6 + this.m_text.h[] + 6
  
  if this.m_svgImage != nil:
    this.m_svgImage.imageWh[] = vec2(this.m_text.h[], this.m_text.h[]).ivec2
    this.m_svgImage.wh = vec2(this.m_text.h[], this.m_text.h[])
    this.m_text.x[] = this.m_svgImage.x[] + this.m_svgImage.w[] + 10


proc onIconChanged(this: Button) =
  if this.icon == nil:
    if this.m_svgImage != nil:
      deteach this.m_svgImage
      this.m_svgImage = nil
      this.m_text.left = this.left + 10
  
  else:
    if this.m_svgImage == nil:
      this.makeLayout:
        - UiSvgImage.new:
          root.m_svgImage = this
          x = 10
          y = 6
          color = binding: root.m_text.color[]

    this.m_svgImage.image[] = this.icon[][].svg

  this.adjustSize()



method init(this: Button) =
  procCall this.super.init()

  this.makeLayout:
    - RectShadow.new:
      w = binding: root.w[] + 12
      h = binding: root.h[] + 12
      y = 1 - 6
      x = -6
      blurRadius = 6
      radius = 5
      color = color_shadow

    - UiRect.new as bg:
      root.m_background = this
      this.fill parent
      radius = 5
      color = binding:
        # todo: focusReason == NOT_MOUSE
        # if currentFocus[] == root: "96AE79".color
        if root.accent[]: color_border_accent_button
        else: color_border_button

      - this.color.transition(0.1's):
        easing = outSquareEasing

      - UiRect.new:
        this.fill parent, 1
        radius = 4
        color = binding:
          if root.accent[]:
            if root.pressed[]: color_bg_accent_button_pressed
            elif root.hovered[]: color_bg_accent_button_hovered
            else: color_bg_accent_button
          else:
            if root.pressed[]: color_bg_button_pressed
            elif root.hovered[]: color_bg_button_hovered
            else: color_bg_button

        - this.color.transition(0.1's):
          easing = outSquareEasing

    - UiText.new:
      root.m_text = this
      y = 6
      x = 10
      font = font_default.withSize(14)

      color = binding:
        if root.accent[]: color_fg_accent
        elif root.pressed[] or root.hovered[]: color_fg_active
        else: color_fg
      
      - this.color.transition(0.1's):
        easing = outSquareEasing
    
    on this.pressed[] == true:
      setFocus root, focusFromMouse
      # todo: unfocus on pressing esc
      # todo: unfocus on pressing on window
  

  this.m_text.w.changed.connectTo this: this.adjustSize()
  this.m_text.h.changed.connectTo this: this.adjustSize()


proc firstHandHandler_hook*(this: Button, name: static string, origType: typedesc) =
  this.super.firstHandHandler_hook(name, origType)

  when name == "icon":
    this.onIconChanged()


when isMainModule:
  import sigui/globalKeybinding

  proc main =
    let win = newSiwinGlobals().newOpenglWindow(size=ivec2(200, 100)).newUiWindow

    win.makeLayout:
      clearColor = color_bg
      - Button.new:
        this.centerIn parent
        text = "Hello, world!"
        icon = "document-new".icon
        on this.clicked:
          echo "clicked!"
        
        - globalKeybinding({Key.space}):
          on this.activated:
            parent.accent[] = not parent.accent[]

        win.siwinWindow.minSize = ivec2(this.w[].int32 + 10, this.h[].int32 + 10)

    run win.siwinWindow
  
  main()


