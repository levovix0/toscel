import std/[math]
import pkg/pixie/[fonts]
import pkg/sigui/[events, properties, uibase, mouseArea, layouts, animations]
import ./[colors, fonts, focus, transitions]

type
  ListWidget* = ref object of MouseArea
    items*: Property[seq[string]]
    selectedItem*: Property[int] = (-1).property
    
    itemSelected*: Event[int]

registerComponent ListWidget

method init*(this: ListWidget) =
  procCall this.super.init()

  this.makeLayout:
    w = width_control_default * 2
    h = 200

    - FocusItem root

    - UiRect.new:
      this.fill(parent)
      color = color_bg
      radius = radius_default

    --- ClipRect.new:
      <--- ClipRect.new: root.items[]
      
      this.fill(parent)
      radius = radius_default

      - Layout.vbox:
        this.fill(parent)
        align = start
        fillContainer = true

        for itemI, item in root.items[]:
          - MouseArea.new:
            h = padding_default_vertical + fontSize_default + padding_default_vertical
            cursor = pointingHand

            - UiRect.new:
              this.fill(parent)
              color = binding:
                if root.selectedItem[] == itemI:
                  if parent.pressed[]: color_bg_accent_button_pressed
                  elif parent.hovered[]: color_bg_accent_button_hovered
                  else: color_bg_accent_button
                else:
                  if parent.pressed[]: color_bg_button_pressed
                  elif parent.hovered[]: color_bg_button_hovered
                  else: color_bg
              
              addTransition this.color

            - UiText.new:
              this.left = parent.left + padding_default_horizontal
              this.centerY = parent.center

              font = font_default.withSize(fontSize_default)
              text = item
              color = binding:
                if root.selectedItem[] == itemI:
                  color_fg_accent
                else:
                  if parent.hovered[]: color_fg_active
                  else: color_fg
              
              addTransition this.color

            on this.mouseDownAndUpInside:
              setFocus root
              root.selectedItem[] = itemI
              root.itemSelected.emit(itemI)

    - UiRectBorder.new:
      layer = after parent
      this.fill(parent)
      radius = radius_default
      borderWidth = borderWidth_default
      color = color_border_button


method recieve*(this: ListWidget, signal: Signal) =
  if signal of WindowEvent and signal.WindowEvent.event of KeyEvent:
    let e = (ref KeyEvent)(signal.WindowEvent.event)
    
    if e.pressed and currentFocus[] == this and not signal.WindowEvent.handled:
      if this.items[].len != 0:
        if e.key == Key.up:
          this.selectedItem[] = (this.selectedItem[] - 1).euclMod(this.items[].len)
          this.itemSelected.emit(this.selectedItem[])
          signal.WindowEvent.handled = true
        elif e.key == Key.down:
          this.selectedItem[] = (this.selectedItem[] + 1).euclMod(this.items[].len)
          this.itemSelected.emit(this.selectedItem[])
          signal.WindowEvent.handled = true

  procCall this.super.recieve(signal)