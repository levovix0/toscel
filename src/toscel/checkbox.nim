import pkg/sigui/[uibase, mouseArea, animations]
import siwin
import ./[icons, fonts, focus, colors]

type
  CheckBox* = ref object of MouseArea
  
  CheckableIcon* = ref object of MouseArea


# todo
