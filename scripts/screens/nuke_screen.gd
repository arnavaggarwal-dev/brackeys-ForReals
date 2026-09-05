class_name NukeScreen
extends RefCounted

const SCENE := "res://scenes/nuke.tscn"

const HEAVY := [
	"res://assets/3d/bomb.glb",
	"res://assets/audio/kaboom.mp3",
]

static var _running := false
static var _warming := false
static var _warm: Dictionary = {}


static func warm() -> void:
	if _warming:
		return
	_warming = true
	for path: String in HEAVY:
		ResourceLoader.load_threaded_request(path)


static func warmed() -> bool:
	if not _warming:
		return false
	for path: String in HEAVY:
		if not _warm.has(path):
			return false
	return true


static func warm_progress() -> float:
	if not _warming:
		return 0.0
	var done := 0.0
	for path: String in HEAVY:
		if _warm.has(path):
			done += 1.0
			continue
		var bits: Array = []
		if ResourceLoader.load_threaded_get_status(path, bits) == ResourceLoader.THREAD_LOAD_LOADED:
			_warm[path] = ResourceLoader.load_threaded_get(path)
			done += 1.0
		elif bits.size() > 0:
			done += float(bits[0])
	return done / float(HEAVY.size())


static func take(path: String) -> Resource:
	if _warm.has(path):
		return _warm[path]
	if _warming:
		var res := ResourceLoader.load_threaded_get(path)
		if res != null:
			_warm[path] = res
			return res
	return load(path)


static func running() -> bool:
	return _running


static func confirm() -> void:
	var body := Dialog.open("Nuke account", 520.0)
	body.add_child(Dialog.message(
		Icon.Kind.WARNING,
		"This deletes the save on this machine. The account, the followers, the "
		+ "payout, the speech fragments and every asset you bought - all of it.",
		Style.ALARM
	))
	body.add_child(Style.spacer(12))
	body.add_child(Style.body(
		"There is no undo, no export, and no appeal. You will be dropped back at "
		+ "the sign-in screen with nothing.",
		Style.ui_r, 13, Style.INK_SOFT, 4
	))
	body.add_child(Style.spacer(10))

	var row := Dialog.buttons()
	var go := Dialog.button("Nuke it", false, Style.ALARM)
	go.pressed.connect(func() -> void:
		Dialog.close()
		play())
	row.add_child(go)
	var no := Dialog.button("Cancel")
	no.pressed.connect(Dialog.close)
	row.add_child(no)
	Dialog.actions(row)


static func play() -> void:
	if _running:
		return
	_running = true
	Game.pause_clock()

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var box := SubViewportContainer.new()
	box.stretch = true
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	var vp := SubViewport.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	box.add_child(vp)

	var scene: Node = load(SCENE).instantiate()
	vp.add_child(scene)

	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)

	root.add_child(_caption())

	scene.flashed.connect(func() -> void:
		flash.color = Color(1, 1, 1, 1)
		var tw := flash.create_tween()
		tw.tween_property(flash, "color", Color(1, 1, 1, 0), 1.2) 			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT))
	scene.finished.connect(_done)

	AppShell.i.mount_veil(root)


static func _caption() -> Control:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_bottom = -56.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED, 16, 9, 16, 10)
	)
	var row := Style.hbox(12)
	var art := SpriteAnim.make("loading", 34.0)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(art)
	row.add_child(Style.label("Deleting your account...", Style.ui_b, 16, Style.INK))
	panel.add_child(row)
	return panel


static func _done() -> void:
	_running = false
	AppShell.i.clear_veil()
	AppShell.i.restart()
	Game.toast_requested.emit("Account deleted", "there is nothing left of it", true)
