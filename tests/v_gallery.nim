import pkg/[sigui]
import toscel


let win =
  when defined(headless): newHeadlessUiWindow(size = ivec2(1280, 720))
  else: newUiWindow(title="Toscel component library galery")

var menuBar: MenuBar
var modal: ModalOverlay
var wordWrap = true


win.makeLayout:
  this.clearColor = binding: color_bg[]


  - Panel(header = "Panel", centerIn(parent)):
    - Layout(col(), align = center, gap = 10):
      parent.w[] = binding: this.w[] + parent.content.x[] + parent.content.margin.bottom
      parent.h[] = binding: this.h[] + parent.content.y[] + parent.content.margin.bottom

      - MenuBar.new as (menuBar):
        this.addMenu("File", @[
          MenuEntry(text: "New", shortcut: "Ctrl+N"),
          MenuEntry(text: "Open", shortcut: "Ctrl+O"),
          menuSeparator(),
          MenuEntry(text: "Exit"),
        ])

        this.addMenu("Edit", @[
          MenuEntry(text: "Undo", shortcut: "Ctrl+Z"),
          MenuEntry(text: "Redo", shortcut: "Ctrl+Shift+Z", disabled: proc(): bool = true),
          menuSeparator(),
          MenuEntry(text: "Word wrap", checkable: true, checked: proc(): bool = wordWrap, action: proc() = wordWrap = not wordWrap),
        ])

        this.addMenu("Settings", @[
          MenuEntry(text: "Dark theme", shortcut: "Ctrl+T", checkable: true, checked: proc(): bool = currentToscelTheme[] == ttkDark, action: proc() =
            setToscelTheme case currentToscelTheme[]
              of ttkDark: ttkLight
              of ttkLight: ttkDark
          ),
        ])

        this.addMenu("Help", @[MenuEntry(text: "About")])

      - Layout(row(), align = center, gap = 10):
        - Label(text = "Label")
        - Button(text = "Button")
        - LineEdit(text = "LineEdit")
        - ComboBox(options = @["ComboBox", "with", "text", "options"], selectedOption = 0)

      - Layout(row(), align = center, gap = 10):
        - Button(text = "Button (disabled)", enabled = false)

      - ListWidget(items = @["ListWidget", "item 2", "item 3", "item 4", "item 5", "item 6", "item 7", "item 8", "item 9"], selectedItem = 2)

      - Button(text = "Show ModalOverlay"):
        on this.clicked: modal.opened[] = true

  - ModalOverlay.new as (modal):
    + this.content:
      w = 300
      h = 130

    - Panel(header = "ModalOverlay"):
      this.fill(parent)

      - Layout(col(), align = center, gap = 10):
        this.centerIn(parent)

        - Label(text = "ModalOverlay content")
        - Button(text = "Close"):
          on this.clicked: modal.opened[] = false


when defined(headless):
  import std/[os]
  createDir("local_screenshots")
  win.saveScreenshot("local_screenshots/gallery.png")

  menuBar.openedIndex[] = 1
  win.saveScreenshot("local_screenshots/gallery_menuBar.png")

  menuBar.openedIndex[] = -1
  modal.opened[] = true
  win.saveScreenshot("local_screenshots/gallery_modalOverlay.png")
else:
  when defined(inspector): openInspector win
  run win

