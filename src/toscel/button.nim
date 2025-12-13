import pkg/sigui/[uibase, mouseArea, animations]
import ./[icons, fonts, focus, colors]

type
  Button* = ref object of MouseArea
    icon*: Property[Icon]
    accent*: Property[bool]
    
    pressedByKeyboard: Property[bool]

    m_background: UiRect
    m_svgImage: UiSvgImage
    m_text: UiText


proc onIconChanged(this: Button)


addFirstHandHandler Button, "icon": onIconChanged(this); redraw(this)


registerComponent Button


proc activated*(this: Button): var Event[void] =
  this.mouseDownAndUpInside


proc text*(this: Button): var Property[string] =
  this.m_text.text


proc adjustSize(this: Button) =
  let textH =
    if this.m_text.h[] == 0:
      if this.m_text.font[] != nil: this.m_text.font[].size + 2
      else: 14 + 2
    else: this.m_text.h[]
  
  let minW =
    10 +
    (if this.icon != nil: textH + 10 else: 0) +
   ( if this.m_text.text != "": this.m_text.w[] + 10 else: 0)

  if this.w[] < minW: this.w[] = minW
  this.h[] = 6 + textH + 6
  
  if this.m_svgImage != nil:
    this.m_svgImage.imageWh[] = vec2(this.m_text.h[], this.m_text.h[]).ivec2
    this.m_svgImage.wh = vec2(this.m_text.h[], this.m_text.h[])
    this.m_text.x[] = this.m_svgImage.x[] + this.m_svgImage.w[] + 10


proc onIconChanged(this: Button) =
  if this.icon == nil:
    if this.m_svgImage != nil:
      delete this.m_svgImage
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
    on currentFocus.changed:
      root.pressedByKeyboard[] = false

    - FocusItem root

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
        if currentFocus[] == root and currentFocusSource notin {focusFromMouse, focusDefault}:
          let c = if root.accent[]: color_border_accent_button.lighten(0.1)
          else: color_border_accent_button
          if root.pressed[] or root.pressedByKeyboard[]: c.darken(0.2)
          else: c
        elif root.accent[]: color_border_accent_button
        else: color_border_button

      - this.color.transition(0.1's):
        easing = outSquareEasing

      - UiRect.new:
        this.fill parent, 1
        radius = 4
        color = binding:
          if root.accent[]:
            if root.pressed[] or root.pressedByKeyboard[]: color_bg_accent_button_pressed
            elif root.hovered[]: color_bg_accent_button_hovered
            else: color_bg_accent_button
          else:
            if root.pressed[] or root.pressedByKeyboard[]: color_bg_button_pressed
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
  

  this.m_text.w.changed.connectTo this: this.adjustSize()
  this.m_text.h.changed.connectTo this: this.adjustSize()


method recieve*(this: Button, signal: Signal) =
  procCall this.super.recieve(signal)

  if currentFocus[] == this:
    if signal of WindowEvent and signal.WindowEvent.event of KeyEvent and signal.WindowEvent.handled == false:
      let e = (ref KeyEvent)signal.WindowEvent.event
      if e.key in {Key.space, Key.enter}:
        signal.WindowEvent.handled = true
        if this.pressedByKeyboard[] and e.pressed == false:
          this.activated.emit()
        this.pressedByKeyboard[] = e.pressed


when isMainModule:
  import sigui/globalKeybinding
  import siwin

  proc main =
    let win = newUiWindow(size=ivec2(200, 100))

    win.makeLayout:
      this.clearColor = color_bg

      - globalKeybinding({Key.space}):
        on this.activated:
          btn.accent[] = not btn.accent[]

      - globalKeybinding({Key.tab}):
        on this.activated:
          setFocus btn
      
      - MouseArea.new:
        this.fill parent

        - FocusItem root

        - Button.new as btn:
          this.centerIn parent
          text = "Hello, world!"
          icon = "document-new".icon
          on this.activated:
            echo "activated!"

          win.siwinWindow.minSize = ivec2(this.w[].int32 + 10, this.h[].int32 + 10)


    run win
  
  main()


