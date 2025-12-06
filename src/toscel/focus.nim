import pkg/sigui/[uiobj, properties, mouseArea]

type
  FocusSource* = enum
    focusFromMouse
    focusFromKeyboard
    focusDefault
    focusProgrammable

  FocusItem* = distinct Uiobj

var currentFocus*: Property[Uiobj]
var currentFocusSource*: FocusSource  # must be changed just before change of currentFocus

# todo: FocusRoot
# todo: implement focusFromKeyboard


proc setFocus*(item: Uiobj, source: FocusSource = focusProgrammable) =
  currentFocusSource = source
  currentFocus[] = item


proc addChild*(parent: MouseArea, focusItem: FocusItem) =
  parent.pressed.changed.connectTo parent:
    if parent.pressed[]:
      focusItem.Uiobj.setFocus focusFromMouse

proc initIfNeeded*(focusItem: FocusItem) = discard
proc markCompleted*(focusItem: FocusItem) = discard
