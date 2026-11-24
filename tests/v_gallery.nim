import pkg/[sigui]
import toscel


let win =
  when defined(headless): newHeadlessUiWindow(size = ivec2(1280, 720))
  else: newUiWindow(title="Toscel component library galery")


win.makeLayout:
  this.clearColor = "202020".color


  - Panel(header = "Panel", centerIn(parent)):
    - Layout(col(), align = center, gap = 10):
      parent.w[] = binding: this.w[] + parent.content.x[] + parent.content.margin.bottom
      parent.h[] = binding: this.h[] + parent.content.y[] + parent.content.margin.bottom

      - Layout(row(), align = center, gap = 10):
        - Label(text = "Label")
        - Button(text = "Button")
        - LineEdit(text = "LineEdit")
        - ComboBox(options = @["ComboBox", "with", "text", "options"], selectedOption = 0)

      - Layout(row(), align = center, gap = 10):
        - Button(text = "Button (disabled)", enabled = false)


when defined(headless):
  import std/[os]
  createDir("local_screenshots")
  win.saveScreenshot("local_screenshots/gallery.png")
else:
  when defined(inspector): openInspector win
  run win

