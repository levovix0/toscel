import std/[macros, strutils]
import pkg/chroma
import pkg/sigui/[colorutils, properties]


type
  ToscelThemeKind* = enum
    ttkDark
    ttkLight

  ToscelTheme* = object
    ## all colors used by toscel widgets;
    ## use `setToscelTheme` to apply
    ## note that a macro below generates global properties for each color
    color_accent* = "#6DE375".color

    color_bg* = "#202020".color

    color_bg_button* = "#282828".color
    color_bg_button_hovered* = "#303030".color
    color_bg_button_pressed* = "#222222".color
    color_bg_button_disabled* = "#303030".color

    color_bg_accent_button* = "#6DE375".color
    color_bg_accent_button_hovered* = "#6DE375".color.lighten(0.1)
    color_bg_accent_button_pressed* = "#6DE375".color.darken(0.1)
    color_bg_accent_button_disabled* = "#303030".color

    color_fg* = "#cbcbcb".color
    color_fg_active* = "#ffffff".color
    color_fg_pressed* = "#ababab".color
    color_fg_accent* = "#202020".color
    color_fg_disabled* = "#8b8b8b".color
    color_fg_placeholder* = "#8b8b8b".color
    color_fg_placeholder_active* = "#ababab".color

    color_border* = "#808080".color

    color_border_button* = "#404040".color
    color_border_button_disabled* = "#404040".color

    color_border_accent_button* = "#6DE375".color.lighten(0.2)
    color_border_accent_button_disabled* = "#404040".color

    color_border_lineEdit* = "#404040".color
    color_border_accent_lineEdit* = "#6DE375".color.lighten(0.2)
    color_border_lineEdit_invalid* = "#f06060".color
    color_border_accent_lineEdit_invalid* = "#f06060".color.lighten(0.1)

    color_border_panel* = "#404040".color

    color_shadow* = "#00000060".color


const
  radius_default* = 5

  borderWidth_default* = 1

  fontSize_default* = 14


  padding_default_horizontal* = 9
  padding_default_vertical* = 9

  padding_panel_horizontal* = padding_default_horizontal * 2
  padding_panel_vertical* = padding_default_vertical * 2


  width_control_default* = 100


const darkTheme* = ToscelTheme()

const lightTheme* = ToscelTheme(
  color_accent: "#3BB44A".color,

  color_bg: "#f3f3f3".color,

  color_bg_button: "#e8e8e8".color,
  color_bg_button_hovered: "#dcdcdc".color,
  color_bg_button_pressed: "#efefef".color,
  color_bg_button_disabled: "#e4e4e4".color,

  color_bg_accent_button: "#3BB44A".color,
  color_bg_accent_button_hovered: "#3BB44A".color.lighten(0.1),
  color_bg_accent_button_pressed: "#3BB44A".color.darken(0.1),
  color_bg_accent_button_disabled: "#e4e4e4".color,

  color_fg: "#333333".color,
  color_fg_active: "#000000".color,
  color_fg_pressed: "#555555".color,
  color_fg_accent: "#ffffff".color,
  color_fg_disabled: "#9a9a9a".color,
  color_fg_placeholder: "#9a9a9a".color,
  color_fg_placeholder_active: "#707070".color,

  color_border: "#a0a0a0".color,

  color_border_button: "#c2c2c2".color,
  color_border_button_disabled: "#c2c2c2".color,

  color_border_accent_button: "#3BB44A".color.darken(0.15),
  color_border_accent_button_disabled: "#c2c2c2".color,

  color_border_lineEdit: "#c2c2c2".color,
  color_border_accent_lineEdit: "#3BB44A".color.darken(0.1),
  color_border_lineEdit_invalid: "#e05c5c".color,
  color_border_accent_lineEdit_invalid: "#e05c5c".color.darken(0.1),

  color_border_panel: "#c2c2c2".color,

  color_shadow: "#00000035".color,
)


var currentToscelTheme* = ttkDark.property
  ## the theme kind that was last set by `setToscelTheme`


macro makeColors =
  result = nnkVarSection.newTree()

  let moduleCode = staticRead currentSourcePath()

  for name, _ in ToscelTheme().fieldPairs:
    let colorIdent = ident(name)
    var line = 0
    var linestart = 0
    let iAt = moduleCode.find(name)
    for i, c in moduleCode:
      if c == '\n':
        inc line
        linestart = i
      if i >= iAt: break
    
    colorIdent.setLineInfo(currentSourcePath(), line+1, (iAt - linestart))

    result.add nnkIdentDefs.newTree(
      nnkPostfix.newTree(
        ident("*"),
        colorIdent
      ),
      newEmptyNode(),
      nnkCall.newTree(
        ident("property"),
        nnkDotExpr.newTree(
          ident("darkTheme"),
          ident(name)
        )
      )
    )

makeColors()


proc setToscelTheme*(p: ToscelTheme) =
  ## sets all live color properties, every binding using them updates
  macro propertyNamed(name: static string): untyped =
    ident(name)

  for name, v in p.fieldPairs:
    propertyNamed(name)[] = v


proc setToscelTheme*(kind: ToscelThemeKind) =
  currentToscelTheme[] = kind
  setToscelTheme case kind
    of ttkDark: darkTheme
    of ttkLight: lightTheme
