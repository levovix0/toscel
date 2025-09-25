import pkg/siwin, pkg/sigui/uibase
import tosiba


let win = newSiwinGlobals().newOpenglWindow(title="Tosiba component library galery").newUiWindow


win.makeLayout:
  clearColor = "202020".color


run win.siwinWindow

