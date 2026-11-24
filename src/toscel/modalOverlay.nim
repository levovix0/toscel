import pkg/sigui/[uibase, mouseArea, animations]
import ./[colors, fonts, transitions]

type
  ModalOverlay* = ref object of MouseArea
    ## fullscreen modal: dim background + a centered content box.
    ## closes on Escape and on a click outside of the content box.
    ## place `ModalOverlay` anywhere in the window (e.g. inside a title bar),
    ## it always covers the whole window when opened.
    ## children added to the overlay are placed into `content`.
    opened*: Property[bool]

    content* {.cursor.}: Uiobj
      ## fill this with the modal contents

registerComponent ModalOverlay


# children of the overlay are placed into `content`,
# these anchors are relative to the content box (like Panel's anchors)
proc left*(this: ModalOverlay, margin: float32 = 0): Anchor =
  this.content.Uiobj.left(margin)

proc right*(this: ModalOverlay, margin: float32 = 0): Anchor =
  this.content.Uiobj.right(margin)

proc top*(this: ModalOverlay, margin: float32 = 0): Anchor =
  this.content.Uiobj.top(margin)

proc bottom*(this: ModalOverlay, margin: float32 = 0): Anchor =
  this.content.Uiobj.bottom(margin)

proc center*(this: ModalOverlay, margin: float32 = 0): Anchor =
  this.content.center(margin)


method init*(this: ModalOverlay) =
  procCall this.super.init()

  this.makeLayout:
    --- Uiobj.new:  # the dim background, recreated when opened state changes
      <--- {update}: root.opened[]

      if root.opened[]:
        # cover the whole window even if the overlay itself is placed in a bar
        x = binding: -root.globalX[]
        y = binding: -root.globalY[]
        w = binding: root.root.w[]
        h = binding: root.root.h[]

        - MouseArea.new:
          # consumes clicks so that they don't reach the ui under the overlay
          this.fill(parent)

          - UiRect.new:
            this.fill(parent)
            color = "#00000070".color

        # close on escape or on click outside of the content
        this.gotSignal.connectTo this, signal:
          if signal of WindowEvent and signal.WindowEvent.event of KeyEvent:
            let e = (ref KeyEvent)(signal.WindowEvent.event)
            if e.pressed and e.key == Key.escape:
              root.opened[] = false

          if signal of WindowEvent and signal.WindowEvent.event of MouseButtonEvent:
            let e = (ref MouseButtonEvent)(signal.WindowEvent.event)
            if e.pressed:
              let pos = this.root.mouseState.pos - root.content.globalXy
              if pos.x notin 0'f32..root.content.w[] or pos.y notin 0'f32..root.content.h[]:
                signal.WindowEvent.handled = true
                root.opened[] = false

    - Uiobj.new as root.content:  # persistent content box, centered in the window
      visibility = binding:
        if root.opened[]: visible else: collapsed

      x = binding: (root.root.w[] - root.content.w[]) / 2 - root.globalX[]
      y = binding: (root.root.h[] - root.content.h[]) / 2 - root.globalY[]

  # children added by the user go into the content box
  this.newChildsObject = this.content
