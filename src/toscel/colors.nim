import pkg/chroma
import pkg/sigui/uiobj


const color_accent* = "#6DE375".color

const color_bg* = "#202020".color
const color_bg_button* = "#282828".color
const color_bg_button_hovered* = "#303030".color
const color_bg_button_pressed* = "#222222".color
const color_bg_accent_button* = color_accent
const color_bg_accent_button_hovered* = color_accent.lighten(0.1)
const color_bg_accent_button_pressed* = color_accent.darken(0.1)

const color_fg* = "#cbcbcb".color
const color_fg_active* = "#ffffff".color
const color_fg_pressed* = "#ababab".color
const color_fg_accent* = "#202020".color
const color_fg_placeholder* = "#8b8b8b".color
const color_fg_placeholder_active* = "#ababab".color

const color_border* = "#808080".color
const color_border_button* = "#404040".color
const color_border_accent_button* = color_accent.lighten(0.2)

const color_border_lineEdit* = color_border_button
const color_border_accent_lineEdit* = color_border_accent_button
const color_border_lineEdit_invalid* = "#f06060".color
const color_border_accent_lineEdit_invalid* = color_border_lineEdit_invalid.lighten(0.1)

const color_shadow* = "#00000060".color

const radius_default* = 5

const borderWidth_default* = 1

const fontSize_default* = 14

const padding_default_horizontal* = 9
const padding_default_vertical* = 9

const width_control_default* = 100

