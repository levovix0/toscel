## non-blocking system file dialogs for linux
##
## prefers the xdg-desktop-portal FileChooser interface (the standard way:
## the file manager of the current desktop environment is shown — nautilus,
## dolphin, nemo, thunar, ...), falls back to zenity and kdialog.
##
## dialogs run in background threads, results are delivered on the main thread
## through `pollFileDialogs`, which should be called every frame
## (convenience: `installFileDialogPolling` connects it to the root's onTick).
## when no backend is available, `onCancel` is called immediately.

import std/[os, osproc, strutils, streams, uri, times, hashes]
import pkg/sigui/[uiobj, events]


type
  FileDialogKind* = enum
    fdOpen   ## choose an existing file
    fdSave   ## choose a path to save to


# ----- results delivered from the worker threads -----

type
  PendingDialog = object
    id: int
    onConfirm: proc(path: string)
    onCancel: proc()

  DialogTask = object
    kind: FileDialogKind
    title, startDir, currentName: string
    id: int

## the callbacks never cross threads: they live in `pendingDialogs` on the
## main thread and are looked up by `id` when the result is delivered.
## (passing closures to the worker thread is not an option: the runtime
## deep-copies thread arguments, so the callback would operate on a full
## copy of every object it captured — e.g. a copy of the whole title bar —
## and its lifetime across threads would be hard to reason about)
var pendingDialogs: seq[PendingDialog]
var nextDialogId = 1

var resultsChannel: Channel[tuple[id: int, confirmed: bool, path: string]]
var resultsChannelInited = false

## number of file dialogs that are currently open; only touched on the
## main thread (incremented when a dialog starts, decremented when its
## result is delivered)
var pendingDialogTasks = 0

proc initResultsChannel() =
  if not resultsChannelInited:
    resultsChannel.open()
    resultsChannelInited = true


proc deliverDialogResult(id: int, confirmed: bool, path: string) =
  ## finds the pending dialog by id, removes it from `pendingDialogs`
  ## and invokes the appropriate callback
  for i, dialog in pendingDialogs:
    if dialog.id == id:
      let callbacks = pendingDialogs[i]
      pendingDialogs.delete i
      if confirmed:
        if callbacks.onConfirm != nil: callbacks.onConfirm(path)
      else:
        if callbacks.onCancel != nil: callbacks.onCancel()
      return


proc pollFileDialogs*() =
  ## delivers results of finished file dialogs; call this every frame
  if not resultsChannelInited: return
  while true:
    let (has, res) = resultsChannel.tryRecv()
    if not has: return
    dec pendingDialogTasks
    deliverDialogResult(res.id, res.confirmed, res.path)


proc installFileDialogPolling*(root: UiRoot) =
  ## connects `pollFileDialogs` to the root's onTick, so dialog callbacks
  ## are delivered every frame
  initResultsChannel()
  root.onTick.connectTo root.eventHandler:
    pollFileDialogs()
    # while a dialog is pending, keep the frame loop alive: on wayland the
    # app is only woken up by frame callbacks of rendered frames, and
    # without ticks the dialog result would never be polled
    if pendingDialogTasks > 0:
      redraw(root)


# ----- backends -----

type FileDialogBackend = enum
  fbUndetermined, fbPortal, fbZenity, fbKdialog, fbNone

var detectedBackend = fbUndetermined


proc detectBackend(): FileDialogBackend =
  when defined(windows):
    fbNone  # todo: windows backend
  else:
    let gdbus = findExe("gdbus")
    if gdbus.len > 0:
      # The portal service is auto-activated on introspection. Do not let a
      # missing/broken D-Bus service prevent trying the other backends.
      try:
        let (outp, code) = execCmdEx(
          quoteShellPosix(gdbus) & " introspect --session --dest org.freedesktop.portal.Desktop " &
          "--object-path /org/freedesktop/portal/desktop")
        if code == 0 and outp.contains("FileChooser"):
          return fbPortal
      except CatchableError:
        discard

    if findExe("zenity").len > 0: fbZenity
    elif findExe("kdialog").len > 0: fbKdialog
    else: fbNone


proc generateToken(): string =
  ## handle_token for the portal request: only [A-Za-z0-9_] is allowed
  let h = abs(hash($epochTime()))
  "t" & $h


proc uriToPath*(u: string): string =
  ## converts "file:///home/user/my%20file" to "/home/user/my file"
  result = u
  if result.startsWith("file://"):
    result = result[7..^1]
  result = decodeUrl(result, false)


proc gdbusByteArray(s: string): string =
  ## gdbus/gvariant text format for an array of bytes: `@ay [47, 104, 0]`
  var items = ""
  for c in s:
    if items.len > 0: items.add ", "
    items.add $c.int
  if items.len > 0: items.add ", 0"
  else: items = "0"
  "@ay [" & items & "]"


# ----- portal backend -----

proc stopDialogProcess(p: Process) =
  ## Best-effort cleanup. A process may already have exited (or failed to
  ## start fully), so cleanup must never take down the worker thread.
  if p == nil: return
  try:
    if p.running(): p.terminate()
  except CatchableError:
    discard
  try:
    p.close()
  except CatchableError:
    discard


proc portalDialogThread(kind: FileDialogKind, title, startDir, currentName: string, id: int) =
  ## Opens a FileChooser portal dialog via the gdbus CLI and waits for its
  ## response. Every failure is reported as cancellation instead of escaping
  ## the worker thread.
  let methodName = (if kind == fdOpen: "OpenFile" else: "SaveFile")

  var options = "{"
  options.add "\"handle_token\": <'" & generateToken() & "'>"
  if startDir.len > 0:
    options.add ", \"current_folder\": <" & gdbusByteArray(startDir) & ">"
  if kind == fdSave and currentName.len > 0:
    options.add ", \"current_name\": <'" & currentName & "'>"
  options.add "}"

  var monitor: Process = nil
  var call: Process = nil
  try:
    # startProcess does not search PATH on Unix unless poUsePath is set.
    # detectBackend() uses findExe(), so the old code could detect gdbus and
    # then fail here with: No such file or directory [gdbus].
    monitor = startProcess(
      "gdbus",
      args = ["monitor", "--session", "--dest", "org.freedesktop.portal.Desktop"],
      options = {poStdErrToStdOut, poUsePath},
    )

    call = startProcess(
      "gdbus",
      args = ["call", "--session",
        "--dest", "org.freedesktop.portal.Desktop",
        "--object-path", "/org/freedesktop/portal/desktop",
        "--method", "org.freedesktop.portal.FileChooser." & methodName,
        "",  # parent window handle
        title,
        options],
      options = {poStdErrToStdOut, poUsePath},
    )

    # The call finishes immediately after sending the D-Bus request.
    let callOutput = call.outputStream.readAll()
    discard call.waitForExit()
    stopDialogProcess(call)
    call = nil

    # The returned handle is where the Response signal will be emitted.
    var handle = ""
    const handlePrefix = "/org/freedesktop/portal/desktop/request/"
    let handleStart = callOutput.find(handlePrefix)
    if handleStart != -1:
      let handleEnd = callOutput.find('\'', handleStart)
      if handleEnd != -1:
        handle = callOutput[handleStart ..< handleEnd]

    if handle.len == 0:
      stopDialogProcess(monitor)
      resultsChannel.send (id: id, confirmed: false, path: "")
      return

    # Read monitor output until the Response signal for this request arrives.
    var response = ""
    var line = ""
    try:
      while monitor.outputStream.readLine(line):
        if line.startsWith(handle) and line.contains("Request.Response"):
          response = line
          # The response block spans several lines until parentheses balance.
          while response.count('(') > response.count(')'):
            if not monitor.outputStream.readLine(line): break
            response.add "\n" & line
          break
    except CatchableError:
      # D-Bus/portal may disappear while the dialog is open.
      discard

    stopDialogProcess(monitor)
    monitor = nil

    # Parse the response: uint32 code (0 = ok, 1 = cancelled) and "uris".
    var code = -1
    let codeStart = response.find("uint32 ")
    if codeStart != -1:
      let rest = response[codeStart + "uint32 ".len .. ^1]
      let numEnd = rest.find(',')
      if numEnd != -1:
        try: code = rest[0 ..< numEnd].strip.parseInt
        except CatchableError: discard

    var chosenPath = ""
    if code == 0:
      let urisStart = response.find("\"uris\"")
      if urisStart != -1:
        # The first quoted URI in the uris variant.
        let afterUris = response[urisStart .. ^1]
        let uriStart = afterUris.find('\'')
        if uriStart != -1:
          let uriEnd = afterUris.find('\'', uriStart + 1)
          if uriEnd != -1:
            chosenPath = uriToPath(afterUris[uriStart + 1 ..< uriEnd])

    if code == 0 and chosenPath.len > 0:
      resultsChannel.send (id: id, confirmed: true, path: chosenPath)
    else:
      resultsChannel.send (id: id, confirmed: false, path: "")
  except CatchableError:
    # Includes OSError when gdbus is missing/unavailable and I/O errors from
    # its pipes. Never allow an external utility failure to crash the app.
    stopDialogProcess(call)
    stopDialogProcess(monitor)
    resultsChannel.send (id: id, confirmed: false, path: "")


# ----- zenity / kdialog backends -----

proc zenityDialogThread(kind: FileDialogKind, title, startDir, currentName: string, id: int) =
  var args = @["--file-selection", "--title", title]
  if kind == fdSave:
    args.add ["--save", "--confirm-overwrite"]
  if startDir.len > 0:
    if kind == fdSave and currentName.len > 0:
      args.add ["--filename", startDir / currentName]
    else:
      args.add ["--filename", startDir]

  var command = findExe("zenity")
  for arg in args:
    command.add " " & quoteShellPosix(arg)

  let (outp, code) = execCmdEx(command)

  let path = outp.strip()
  if code == 0 and path.len > 0:
    resultsChannel.send (id: id, confirmed: true, path: path)
  else:
    resultsChannel.send (id: id, confirmed: false, path: "")


proc kdialogDialogThread(kind: FileDialogKind, title, startDir, currentName: string, id: int) =
  let start = (if kind == fdSave and currentName.len > 0: startDir / currentName else: startDir)
  let arg = (if kind == fdOpen: "--getopenfilename" else: "--getsavefilename")
  let command =
    findExe("kdialog") & " " & arg & " " & quoteShellPosix(start) &
    " \"*\" --title " & quoteShellPosix(title)

  let (outp, code) = execCmdEx(command)

  let path = outp.strip()
  if code == 0 and path.len > 0:
    resultsChannel.send (id: id, confirmed: true, path: path)
  else:
    resultsChannel.send (id: id, confirmed: false, path: "")


# ----- dispatch -----

var taskChannel: Channel[DialogTask]

## the `Thread` object must outlive the thread: `createThread` passes
## `addr(thread)` to pthread and the worker dereferences it, so a local
## `var thread` would leave a dangling stack pointer as soon as the proc
## that created it returns, crashing the app when that stack memory is
## reused. one global worker thread is created for the whole app lifetime
var workerThread: Thread[void]

proc dialogWorker {.thread.} =
  ## One long-lived worker thread for all dialogs, reading tasks from
  ## `taskChannel`. A backend failure must finish only the current request.
  while true:
    let task = taskChannel.recv()
    try:
      case detectedBackend
      of fbPortal:
        portalDialogThread(task.kind, task.title, task.startDir, task.currentName, task.id)
      of fbZenity:
        zenityDialogThread(task.kind, task.title, task.startDir, task.currentName, task.id)
      of fbKdialog:
        kdialogDialogThread(task.kind, task.title, task.startDir, task.currentName, task.id)
      else:
        resultsChannel.send (id: task.id, confirmed: false, path: "")
    except CatchableError:
      # A failed dialog is equivalent to cancellation; keep the worker alive.
      resultsChannel.send (id: task.id, confirmed: false, path: "")


var workerStarted = false

proc startWorker() =
  if not workerStarted:
    taskChannel.open()
    workerThread.createThread(dialogWorker)
    workerStarted = true


proc runFileDialog*(kind: FileDialogKind, title: string, startDir: string, currentName: string,
    onConfirm: proc(path: string), onCancel: proc() = nil) =
  ## opens a system file dialog without blocking, `onConfirm` receives the
  ## chosen path, `onCancel` is called when the dialog is dismissed
  ## or no backend is available
  initResultsChannel()

  if detectedBackend == fbUndetermined:
    try:
      detectedBackend = detectBackend()
    except CatchableError:
      detectedBackend = fbNone

  # A stale/removed working directory is not a valid initial folder. Let the
  # desktop portal or fallback backend choose its own default instead.
  var safeStartDir = startDir
  if safeStartDir.len > 0:
    try:
      if not dirExists(safeStartDir): safeStartDir = ""
    except CatchableError:
      safeStartDir = ""

  if detectedBackend == fbNone:
    if onCancel != nil: onCancel()
    return

  let id = nextDialogId
  inc nextDialogId
  pendingDialogs.add PendingDialog(id: id, onConfirm: onConfirm, onCancel: onCancel)

  startWorker()
  taskChannel.send DialogTask(
    kind: kind,
    title: title,
    startDir: safeStartDir,
    currentName: currentName,
    id: id,
  )
  inc pendingDialogTasks


proc openFilePanel*(title: string, startDir: string, onConfirm: proc(path: string), onCancel: proc() = nil) =
  runFileDialog(fdOpen, title, startDir, "", onConfirm, onCancel)


proc saveFilePanel*(title: string, defaultPath: string, onConfirm: proc(path: string), onCancel: proc() = nil) =
  ## `defaultPath` is a full path the save dialog starts from (dir + name)
  runFileDialog(fdSave, title, defaultPath.splitPath.head, defaultPath.splitPath.tail, onConfirm, onCancel)
