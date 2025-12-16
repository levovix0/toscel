import std/[math]
import pkg/pixie/[fonts]
import pkg/sigui/[events, properties, uibase, mouseArea, layouts, animations]
import ./[colors, icons, fonts, lineEdit, transitions]


type
  ComboBox* = ref object of Uiobj
    options*: Property[seq[string]]
    selectedOption*: Property[int]

    dropdownOpened*: Property[bool]
    fitOptionsWidth*: Property[bool] = true.property
    otherTextCanBeEntered*: Property[bool]

    binding_valid*: EventHandler
      ## to allow all text be valid or customize validation,
      ## use `disconnect this.binding_valid` and create new binding for `this.valid` or assign a value to it
    
    lineEdit*: LineEdit

registerComponent ComboBox


template text*(this: ComboBox): var Property[string] =
  this.lineEdit.text

template valid*(this: ComboBox): var Property[bool] =
  this.lineEdit.valid

template placeholder*(this: ComboBox): var Property[string] =
  this.lineEdit.placeholder


method init*(this: ComboBox) =
  procCall this.super.init()

  this.makeLayout:
    w = width_control_default
    h = padding_default_horizontal + fontSize_default + padding_default_horizontal

    on root.options.changed:
      if not root.fitOptionsWidth[]: return

      var maxW = 0'f32
      for text in root.options[]:
        let w = font_default.withSize(fontSize_default).layoutBounds(text).x
        maxW = max(w, maxW)
      
      this.w[] = padding_default_horizontal + maxW + 2 + padding_default_horizontal + fontSize_default + padding_default_horizontal


    - LineEdit.new:
      this.fill(parent)
      root.lineEdit = this

      valid = binding(root.binding_valid): this.text[] in root.options[]
      
      binding:
        if root.selectedOption[] in 0..root.options[].high:
          this.text.val = root.options[][root.selectedOption[]]

      on this.textArea.textEdited:
        let i = root.options[].find(this.text[])
        if i != -1:
          root.selectedOption[] = i
        elif root.otherTextCanBeEntered[]:
          root.selectedOption[] = -1

      - MouseArea.new as dropdownButton:
        w = padding_default_horizontal + fontSize_default + padding_default_horizontal
        h = this.w[]
        right = parent.right
      
        - UiSvgImage.new:
          w = fontSize_default
          h = fontSize_default
          this.centerIn(parent)
          
          image = "arrow-down".icon.svg
          color = binding:
            if parent.pressed[]: color_fg_pressed
            elif parent.hovered[]: color_fg_active
            else: color_fg
        
        on this.mouseDownAndUpInside:
          root.dropdownOpened[] = not root.dropdownOpened[]
      
      + this.textArea.textArea:
        this.right = dropdownButton.left
      
      + this.textArea.mouseArea:
        this.right = dropdownButton.left

    
    --- ClipRect.new:
      <--- ClipRect.new: root.dropdownOpened[]; root.options[]

      drawLayer = after root.parentUiRoot
      # todo: global menu/popup layer
      # todo: signalLayer

      if root.dropdownOpened[]:
        let optionHeight = parent.h[]

        w = binding: parent.w[]
        h = root.options[].len.float32 * optionHeight
        y = binding: root.selectedOption[].float32 * -optionHeight
        radius = radius_default

        this.onSignal.connectTo this, signal:
          if signal of WindowEvent and signal.WindowEvent.event of MouseButtonEvent:
            let e = (ref MouseButtonEvent)(signal.WindowEvent.event)
            if e.pressed:
              let pos = this.parentUiRoot.mouseState.pos - this.globalXy
              if pos.x notin 0'f32..this.w[] or pos.y notin 0'f32..this.h[]:
                root.dropdownOpened[] = false
          
          if signal of WindowEvent and signal.WindowEvent.event of ScrollEvent:
            let e = (ref ScrollEvent)(signal.WindowEvent.event)
            if not signal.WindowEvent.handled:
              if root.options[].len != 0:
                if e.delta > 0:
                  root.selectedOption[] = (root.selectedOption[] + 1).clamp(0, root.options[].high)
                  signal.WindowEvent.handled = true
                elif e.delta < 0:
                  root.selectedOption[] = (root.selectedOption[] - 1).clamp(0, root.options[].high)
                  signal.WindowEvent.handled = true
          
          if signal of WindowEvent and signal.WindowEvent.event of KeyEvent:
            let e = (ref KeyEvent)(signal.WindowEvent.event)
            if not signal.WindowEvent.handled:
              if e.key in {Key.space, Key.enter}:
                root.dropdownOpened[] = false
                signal.WindowEvent.handled = true


        addTransition this.y

        - Layout.vbox:
          this.fill(parent)
          align = start
          fillContainer = true

          for optionI, option in root.options[]:
            - MouseArea.new:
              h = optionHeight

              cursor = pointingHand

              - UiRect.new:
                this.fill(parent)

                color = binding:
                  if root.selectedOption[] == optionI:
                    if parent.pressed[]: color_bg_accent_button_pressed
                    elif parent.hovered[]: color_bg_accent_button_hovered
                    else: color_bg_accent_button
                  else:
                    if parent.pressed[]: color_bg_button_pressed
                    elif parent.hovered[]: color_bg_button_hovered
                    else: color_bg_button
                
                addTransition this.color

              - UiText.new:
                this.left = parent.left + padding_default_horizontal
                this.centerY = parent.center

                font = font_default.withSize(fontSize_default)
                text = option
                color = binding:
                  if root.selectedOption[] == optionI:
                    color_fg_accent
                  else:
                    if parent.hovered[]: color_fg_active
                    else: color_fg
                
                addTransition this.color
              
              on this.mouseDownAndUpInside:
                root.selectedOption[] = optionI
                root.dropdownOpened[] = false
        
        - UiRectBorder.new:
          this.drawLayer = after parent
          this.fill(parent)
          radius = radius_default - 2
          borderWidth = borderWidth_default
          color = color_border_lineEdit



method recieve*(this: ComboBox, signal: Signal) =
  if signal of WindowEvent and signal.WindowEvent.event of ScrollEvent:
    let e = (ref ScrollEvent)(signal.WindowEvent.event)
    if not signal.WindowEvent.handled and not this.dropdownOpened[]:
      let pos = this.parentUiRoot.mouseState.pos - this.globalXy
      if pos.x in 0'f32..this.w[] and pos.y in 0'f32..this.h[]:
        if this.options[].len != 0:
          if e.delta > 0:
            this.selectedOption[] = (this.selectedOption[] + 1).euclMod(this.options[].len)
            signal.WindowEvent.handled = true
          elif e.delta < 0:
            this.selectedOption[] = (this.selectedOption[] - 1).euclMod(this.options[].len)
            signal.WindowEvent.handled = true
      
  if signal of WindowEvent and signal.WindowEvent.event of KeyEvent:
    let e = (ref KeyEvent)(signal.WindowEvent.event)
    if e.pressed:
      if this.lineEdit.textArea.active[] and not signal.WindowEvent.handled:
        if e.key == Key.up:
          if this.options[].len != 0:
            this.selectedOption[] = (this.selectedOption[] - 1).euclMod(this.options[].len)
            signal.WindowEvent.handled = true
        
        elif e.key == Key.down:
          if this.options[].len != 0:
            this.selectedOption[] = (this.selectedOption[] + 1).euclMod(this.options[].len)
            signal.WindowEvent.handled = true
  
  procCall this.super.recieve(signal)

