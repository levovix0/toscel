## runtime theming for toscel widgets
##
## colors in `colors` are live properties: widgets read them inside `binding:` blocks,
## so changing the theme updates the whole UI.
## `applyPalette` allows fully custom palettes, not only the built-in dark/light ones.

import pkg/sigui/properties
import ./colors

export colors
