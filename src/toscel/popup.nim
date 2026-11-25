import pkg/sigui/[uibase]

template popupAutoClose*(popup: Uiobj, closeBody: untyped) {.dirty.} =
  ## closes the popup (runs `closeBody`) when clicking outside of it, or on escape
  popup.gotSignal.connectTo popup, signal:
    if signal of WindowEvent and signal.WindowEvent.event of KeyEvent:
      let e = (ref KeyEvent)(signal.WindowEvent.event)
      if e.pressed and e.key == Key.escape:
        closeBody

    if signal of WindowEvent and signal.WindowEvent.event of MouseButtonEvent:
      let e = (ref MouseButtonEvent)(signal.WindowEvent.event)
      if e.pressed:
        let pos = popup.root.mouseState.pos - popup.globalXy
        if pos.x notin 0'f32..popup.w[] or pos.y notin 0'f32..popup.h[]:
          closeBody
