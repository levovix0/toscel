import sigui/[uiobj, properties]

type
  FocusSource* = enum
    focusFromMouse
    focusFromKeyboard
    focusDefault
    focusProgrammable

var currentFocus*: Property[Uiobj]
var currentFocusSource*: FocusSource  # must be changed just before change of currentFocus


proc setFocus*(item: Uiobj, source: FocusSource = focusProgrammable) =
  currentFocusSource = source
  currentFocus[] = item


type
  FocusItem* = object


proc addChild*(parent: Uiobj, _: typedesc[FocusItem]) =
  parent.onSignal.connectTo parent:
    ##

