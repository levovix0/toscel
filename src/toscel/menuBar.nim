import std/[math]
import pkg/sigui/[uibase, mouseArea, animations]
import ./[colors, fonts, transitions, icons]

type
  MenuEntry* = object
    ## a single row of a dropdown menu.
    ## note: the fields are plain values and procs (not properties),
    ## because entries are stored in a seq and are re-evaluated every
    ## time the menu is opened
    text*: string
    shortcut*: string
      ## hint displayed on the right (e.g. "Ctrl+O"),
      ## registering the actual keybinding is up to the application
    checkable*: bool
    checked*: proc(): bool = nil
      ## for checkable entries, evaluated when the menu opens;
      ## the action is responsible for changing the underlying state
    disabled*: proc(): bool = nil
      ## nil = always enabled, evaluated when the menu opens
    action*: proc()
    isSeparator*: bool

  MenuButton* = ref object of MouseArea
    ## a menubar button that opens a dropdown menu with `entries`
    text*: Property[string]
    entries*: Property[seq[MenuEntry]]
    opened*: Property[bool]

    menuBar: MenuBar
    index: int

  MenuBar* = ref object of Uiobj
    ## horizontal menubar: a row of MenuButtons with dropdown menus,
    ## only one menu is opened at a time
    openedIndex*: Property[int] = (-1).property
      ## index of the menu that is currently opened, -1 = closed

    buttons: seq[MenuButton]

registerComponent MenuButton
registerComponent MenuBar


proc menuSeparator*(): MenuEntry =
  MenuEntry(isSeparator: true)


const menuFontSize = 13'f32
const menuRowHeight = 26'f32
const menuPad = 6'f32
const menuCheckAreaWidth = 16'f32
const menuShortcutGap = 16'f32


proc adjustButtonSize(this: MenuButton) =
  let font = font_default.withSize(menuFontSize)
  this.w[] = 2 * 7 + font.layoutBounds(this.text[]).x


proc layoutButtons(this: MenuBar) =
  var x = 0'f32
  for button in this.buttons:
    button.x[] = x
    x += button.w[]
  this.w[] = x


proc openMenu(this: MenuButton) =
  this.menuBar.openedIndex[] = this.index


method init(this: MenuButton) =
  procCall this.super.init()

  this.makeLayout:
    - UiRect.new:
      this.fill(parent)
      radius = 4

      color = binding:
        if root.opened[]: color_bg_button_pressed[]
        elif parent.hovered[]: color_bg_button_hovered[]
        else: "#00000000".color

      addTransition this.color

    - UiText.new:
      this.centerIn(parent)

      font = font_default.withSize(menuFontSize)
      text = binding: root.text[]
      color = binding:
        if root.opened[] or parent.hovered[]: color_fg_active[]
        else: color_fg[]

      addTransition this.color

    on this.clicked:
      if root.menuBar.openedIndex[] == root.index:
        root.menuBar.openedIndex[] = -1
      else:
        root.openMenu()

    on root.hovered.changed:
      # hovering another menubar button while a menu is opened switches to it
      if root.hovered[] and root.menuBar.openedIndex[] != -1 and root.menuBar.openedIndex[] != root.index:
        root.openMenu()

    on root.text.changed:
      root.adjustButtonSize()

    opened = binding:
      root.menuBar.openedIndex[] == root.index

    --- Uiobj.new:  # dropdown, recreated when opened state or entries change
      <--- {update}: root.opened[]; root.entries[]

      if root.opened[]:
        let font = font_default.withSize(menuFontSize)
        let rowH = menuRowHeight

        # the dropdown must be above all other menubar content
        this.layer = root.menuBar.after

        var maxTextW = 0'f32
        var maxShortcutW = 0'f32
        var rowsCount = 0'f32
        for entry in root.entries[]:
          if entry.isSeparator:
            rowsCount += 0.5
          else:
            rowsCount += 1
            (maxTextW) = max(maxTextW, font.layoutBounds(entry.text).x)
            if entry.shortcut.len > 0:
              (maxShortcutW) = max(maxShortcutW, font.layoutBounds(entry.shortcut).x)

        this.w[] = menuPad * 2 + menuCheckAreaWidth + maxTextW +
          (if maxShortcutW > 0: menuShortcutGap + maxShortcutW else: 0'f32) + 2
        this.h[] = rowsCount * rowH
        this.x[] = 0
        this.y[] = parent.h[]

        # close on escape always, on click outside of the dropdown and the menubar,
        # clicks on the menubar are handled by the menubar buttons themselves
        this.gotSignal.connectTo this, signal:
          if signal of WindowEvent and signal.WindowEvent.event of KeyEvent:
            let e = (ref KeyEvent)(signal.WindowEvent.event)
            if e.pressed and e.key == Key.escape:
              root.menuBar.openedIndex[] = -1

          if signal of WindowEvent and signal.WindowEvent.event of MouseButtonEvent:
            let e = (ref MouseButtonEvent)(signal.WindowEvent.event)
            if e.pressed:
              let pos = this.root.mouseState.pos - this.globalXy
              if pos.x notin 0'f32..this.w[] or pos.y notin 0'f32..this.h[]:
                let barPos = this.root.mouseState.pos - root.menuBar.globalXy
                if barPos.x notin 0'f32..root.menuBar.w[] or barPos.y notin 0'f32..root.menuBar.h[]:
                  root.menuBar.openedIndex[] = -1

        - UiRect.new:
          this.fill(parent)
          radius = 5
          color = color_bg_button[]

        - Uiobj.new:  # rows
          this.fill(parent)

          var rowY = 0'f32
          for entryI, entry in root.entries[]:
            var entry = entry

            if entry.isSeparator:
              - UiRect.new:
                x = menuPad
                y = rowY + menuRowHeight / 2 - 6
                w = parent.w[] - menuPad * 2
                h = 1
                color = color_border_button[]

              rowY += menuRowHeight / 2

            else:
              let enabled = (entry.disabled == nil) or (not entry.disabled())
              let checked = entry.checkable and entry.checked != nil and entry.checked()

              - MouseArea.new:
                x = 0
                y = rowY
                w = parent.w[]
                h = rowH
                cursor = pointingHand

                - UiRect.new:
                  this.fill(parent)
                  radius = 4

                  color = binding:
                    if not enabled: "#00000000".color
                    elif parent.pressed[]: color_bg_button_pressed[]
                    elif parent.hovered[]: color_bg_button_hovered[]
                    else: "#00000000".color

                  addTransition this.color

                if entry.checkable:
                  - UiSvgImage.new:
                    x = menuPad
                    centerY = parent.center
                    w = 12
                    h = 12

                    image = "check".icon.svg
                    color = binding:
                      if not enabled: color_fg_disabled[]
                      elif parent.hovered[]: color_fg_active[]
                      else: color_fg[]
                    visibility = (if checked: visible else: collapsed)

                - UiText.new:
                  x = menuPad + menuCheckAreaWidth
                  centerY = parent.center

                  font = font
                  text = entry.text
                  color = binding:
                    if not enabled: color_fg_disabled[]
                    elif parent.hovered[]: color_fg_active[]
                    else: color_fg[]

                  addTransition this.color

                if entry.shortcut.len > 0:
                  - UiText.new:
                    right = parent.right - menuPad
                    centerY = parent.center

                    font = font
                    text = entry.shortcut
                    color = binding:
                      if not enabled: color_fg_disabled[]
                      elif parent.hovered[]: color_fg_active[]
                      else: color_fg_placeholder[]

                on this.clicked:
                  if not enabled: return
                  if entry.action != nil:
                    entry.action()
                  root.menuBar.openedIndex[] = -1

              rowY += rowH

        - UiRectBorder.new:
          layer = after parent
          this.fill(parent)
          radius = 5
          borderWidth = borderWidth_default
          color = color_border_button[]


proc clearMenus*(this: MenuBar) =
  ## removes all menus, e.g. to rebuild them in another language
  let buttons = this.buttons
  this.buttons = @[]
  this.openedIndex[] = -1
  for button in buttons:
    delete button


proc addMenu*(this: MenuBar, title: string, entries: seq[MenuEntry]) =
  ## adds a menu; to rebuild menus (e.g. in another language),
  ## use `clearMenus` and add them again
  let button = MenuButton()
  button.menuBar = this
  button.index = this.buttons.len
  this.buttons.add button

  this.addChild(button)
  # addChild doesn't run init; without this the button would have
  # no contents and no click handlers
  initIfNeeded(button)

  button.text[] = title
  button.entries[] = entries
  button.h[] = this.h[]
  button.adjustButtonSize()

  this.h.changed.connectTo button.eventHandler:
    button.h[] = this.h[]

  button.w.changed.connectTo this.eventHandler:
    this.layoutButtons()

  this.layoutButtons()


method init*(this: MenuBar) =
  procCall this.super.init()

  this.h[] = 30
