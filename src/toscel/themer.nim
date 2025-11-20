# note: themes are currently not supported
# todo

when false:
  import pkg/sigui/[uiobj, events, properties, styles]


  type
    TosibaTheme* = enum
      SystemTheme
      DarkTheme
      LightTheme

    Themer* = ref object of Styler
      theme*: Property[TosibaTheme]

      currentTheme: TosibaTheme


  proc onThemeChanged*(this: Themer)

  addFirstHandHandler Themer, "theme": onThemeChanged(this)


  registerComponent Themer


  proc systemTheme*: TosibaTheme =
    DarkTheme


  proc themeToUse(theme: TosibaTheme): TosibaTheme =
    if theme == SystemTheme: systemTheme()
    else: theme


  proc styleForTheme(theme: TosibaTheme): proc(uiobj: Uiobj) =
    case theme
    of SystemTheme:
      nil  # should not happen
    
    of DarkTheme:
      makeStyle:
        ## todo
    
    of LightTheme:
      makeStyle:
        ## todo


  proc on_currentTheme_changed(this: Themer) =
    this.style[] = this.currentTheme.styleForTheme()


  proc onThemeChanged*(this: Themer) =
    let t = this.theme[].themeToUse()
    if this.currentTheme != t:
      this.currentTheme = t
      this.on_currentTheme_changed()


