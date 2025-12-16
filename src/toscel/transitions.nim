import pkg/sigui/[uiobj, properties, events, animations]

type
  DialogAppearanceTransition* = ref object of Uiobj
    startNow*: bool = true

registerComponent DialogAppearanceTransition



# --- Utils ---

proc findLastIncompleteParent*(this: Uiobj): Uiobj =
  result = this
  while result.parent != nil and not result.parent.isCompleted:
    result = result.parent

template addTransition*[T](prop: var Property[T], duration = 0.1's, easingProc = outSquareEasing) {.dirty.} =
  bind transition, addChild, connect, outSquareEasing, findLastIncompleteParent
  block:
    let trans = transition(prop, duration)
    trans.easing[] = easingProc
    connect(findLastIncompleteParent(this).completed, this.eventHandler, proc() = addChild(this, trans))



# --- DialogAppearanceTransition ---

template target*(this: DialogAppearanceTransition): Uiobj =
  this.parent


proc start*(this: DialogAppearanceTransition, appear = true) =
  ## todo


proc markCompleted*(this: DialogAppearanceTransition) =
  if this.startNow:
    this.start(appear = this.target.visibility[] == visible)
  
  markCompleted this.Uiobj

