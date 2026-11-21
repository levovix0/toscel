import pkg/chroma
import pkg/sigui/[uiobj, properties]


type
  ToscelThemeKind* = enum
    ttkDark
    ttkLight

  Palette* = object
    ## all colors used by toscel widgets; assigned to the live color properties by `applyPalette`
    accent*: Color

    bg*: Color

    bgButton*: Color
    bgButtonHovered*: Color
    bgButtonPressed*: Color
    bgButtonDisabled*: Color

    bgAccentButton*: Color
    bgAccentButtonHovered*: Color
    bgAccentButtonPressed*: Color
    bgAccentButtonDisabled*: Color

    fg*: Color
    fgActive*: Color   ## for hovered and pressed controls
    fgPressed*: Color  ## for icon-like buttons
    fgAccent*: Color   ## for controls with background bgAccentButton
    fgDisabled*: Color
    fgPlaceholder*: Color
    fgPlaceholderActive*: Color

    border*: Color

    borderButton*: Color
    borderButtonDisabled*: Color

    borderAccentButton*: Color
    borderAccentButtonDisabled*: Color

    borderLineEdit*: Color
    borderAccentLineEdit*: Color
    borderLineEditInvalid*: Color
    borderAccentLineEditInvalid*: Color

    borderPanel*: Color

    shadow*: Color


proc darkPalette*(): Palette =
  Palette(
    accent: "#6DE375".color,

    bg: "#202020".color,

    bgButton: "#282828".color,
    bgButtonHovered: "#303030".color,
    bgButtonPressed: "#222222".color,
    bgButtonDisabled: "#303030".color,

    bgAccentButton: "#6DE375".color,
    bgAccentButtonHovered: "#6DE375".color.lighten(0.1),
    bgAccentButtonPressed: "#6DE375".color.darken(0.1),
    bgAccentButtonDisabled: "#303030".color,

    fg: "#cbcbcb".color,
    fgActive: "#ffffff".color,
    fgPressed: "#ababab".color,
    fgAccent: "#202020".color,
    fgDisabled: "#8b8b8b".color,
    fgPlaceholder: "#8b8b8b".color,
    fgPlaceholderActive: "#ababab".color,

    border: "#808080".color,

    borderButton: "#404040".color,
    borderButtonDisabled: "#404040".color,

    borderAccentButton: "#6DE375".color.lighten(0.2),
    borderAccentButtonDisabled: "#404040".color,

    borderLineEdit: "#404040".color,
    borderAccentLineEdit: "#6DE375".color.lighten(0.2),
    borderLineEditInvalid: "#f06060".color,
    borderAccentLineEditInvalid: "#f06060".color.lighten(0.1),

    borderPanel: "#404040".color,

    shadow: "#00000060".color,
  )


proc lightPalette*(): Palette =
  Palette(
    accent: "#3BB44A".color,

    bg: "#f3f3f3".color,

    bgButton: "#e8e8e8".color,
    bgButtonHovered: "#dcdcdc".color,
    bgButtonPressed: "#efefef".color,
    bgButtonDisabled: "#e4e4e4".color,

    bgAccentButton: "#3BB44A".color,
    bgAccentButtonHovered: "#3BB44A".color.lighten(0.1),
    bgAccentButtonPressed: "#3BB44A".color.darken(0.1),
    bgAccentButtonDisabled: "#e4e4e4".color,

    fg: "#333333".color,
    fgActive: "#000000".color,
    fgPressed: "#555555".color,
    fgAccent: "#ffffff".color,
    fgDisabled: "#9a9a9a".color,
    fgPlaceholder: "#9a9a9a".color,
    fgPlaceholderActive: "#707070".color,

    border: "#a0a0a0".color,

    borderButton: "#c2c2c2".color,
    borderButtonDisabled: "#c2c2c2".color,

    borderAccentButton: "#3BB44A".color.darken(0.15),
    borderAccentButtonDisabled: "#c2c2c2".color,

    borderLineEdit: "#c2c2c2".color,
    borderAccentLineEdit: "#3BB44A".color.darken(0.1),
    borderLineEditInvalid: "#e05c5c".color,
    borderAccentLineEditInvalid: "#e05c5c".color.darken(0.1),

    borderPanel: "#c2c2c2".color,

    shadow: "#00000035".color,
  )


# ----- live colors, read these with `[]` so that bindings track theme changes -----

var color_accent* = darkPalette().accent.property

var color_bg* = darkPalette().bg.property

var color_bg_button* = darkPalette().bgButton.property
var color_bg_button_hovered* = darkPalette().bgButtonHovered.property
var color_bg_button_pressed* = darkPalette().bgButtonPressed.property
var color_bg_button_disabled* = darkPalette().bgButtonDisabled.property

var color_bg_accent_button* = darkPalette().bgAccentButton.property
var color_bg_accent_button_hovered* = darkPalette().bgAccentButtonHovered.property
var color_bg_accent_button_pressed* = darkPalette().bgAccentButtonPressed.property
var color_bg_accent_button_disabled* = darkPalette().bgAccentButtonDisabled.property

var color_fg* = darkPalette().fg.property
var color_fg_active* = darkPalette().fgActive.property
var color_fg_pressed* = darkPalette().fgPressed.property
var color_fg_accent* = darkPalette().fgAccent.property
var color_fg_disabled* = darkPalette().fgDisabled.property
var color_fg_placeholder* = darkPalette().fgPlaceholder.property
var color_fg_placeholder_active* = darkPalette().fgPlaceholderActive.property

var color_border* = darkPalette().border.property

var color_border_button* = darkPalette().borderButton.property
var color_border_button_disabled* = darkPalette().borderButtonDisabled.property

var color_border_accent_button* = darkPalette().borderAccentButton.property
var color_border_accent_button_disabled* = darkPalette().borderAccentButtonDisabled.property

var color_border_lineEdit* = darkPalette().borderLineEdit.property
var color_border_accent_lineEdit* = darkPalette().borderAccentLineEdit.property
var color_border_lineEdit_invalid* = darkPalette().borderLineEditInvalid.property
var color_border_accent_lineEdit_invalid* = darkPalette().borderAccentLineEditInvalid.property

var color_border_panel* = darkPalette().borderPanel.property

var color_shadow* = darkPalette().shadow.property

var currentToscelTheme* = ttkDark.property
  ## the theme kind that was last set by `setToscelTheme`


proc applyPalette*(p: Palette) =
  ## sets all live color properties, every binding using them updates
  color_accent[] = p.accent

  color_bg[] = p.bg

  color_bg_button[] = p.bgButton
  color_bg_button_hovered[] = p.bgButtonHovered
  color_bg_button_pressed[] = p.bgButtonPressed
  color_bg_button_disabled[] = p.bgButtonDisabled

  color_bg_accent_button[] = p.bgAccentButton
  color_bg_accent_button_hovered[] = p.bgAccentButtonHovered
  color_bg_accent_button_pressed[] = p.bgAccentButtonPressed
  color_bg_accent_button_disabled[] = p.bgAccentButtonDisabled

  color_fg[] = p.fg
  color_fg_active[] = p.fgActive
  color_fg_pressed[] = p.fgPressed
  color_fg_accent[] = p.fgAccent
  color_fg_disabled[] = p.fgDisabled
  color_fg_placeholder[] = p.fgPlaceholder
  color_fg_placeholder_active[] = p.fgPlaceholderActive

  color_border[] = p.border

  color_border_button[] = p.borderButton
  color_border_button_disabled[] = p.borderButtonDisabled

  color_border_accent_button[] = p.borderAccentButton
  color_border_accent_button_disabled[] = p.borderAccentButtonDisabled

  color_border_lineEdit[] = p.borderLineEdit
  color_border_accent_lineEdit[] = p.borderAccentLineEdit
  color_border_lineEdit_invalid[] = p.borderLineEditInvalid
  color_border_accent_lineEdit_invalid[] = p.borderAccentLineEditInvalid

  color_border_panel[] = p.borderPanel

  color_shadow[] = p.shadow


proc setToscelTheme*(kind: ToscelThemeKind) =
  currentToscelTheme[] = kind
  applyPalette (case kind
    of ttkDark: darkPalette()
    of ttkLight: lightPalette())


const radius_default* = 5

const borderWidth_default* = 1

const fontSize_default* = 14


const padding_default_horizontal* = 9
const padding_default_vertical* = 9

const padding_panel_horizontal* = padding_default_horizontal * 2
const padding_panel_vertical* = padding_default_vertical * 2


const width_control_default* = 100
