import pkg/sigui/[properties, uiobj]

type
  DialogAppearanceTransition* = ref object of Uiobj
    startNow*: bool = true


template target*(this: DialogAppearanceTransition): Uiobj =
  this.parent


proc start*(this: DialogAppearanceTransition, appear = true) =
  ## todo


proc markCompleted*(this: DialogAppearanceTransition) =
  if this.startNow:
    this.start(appear = this.target.visibility[] == visible)
  
  markCompleted this.Uiobj


