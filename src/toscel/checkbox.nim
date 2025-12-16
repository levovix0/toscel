import pkg/sigui/[uibase, mouseArea]
# import ./[icons, fonts]

type
  CheckBox* = ref object of MouseArea
  
  CheckableIcon* = ref object of MouseArea

registerComponent CheckBox
registerComponent CheckableIcon

# todo
