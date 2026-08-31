class_name Taskbar
extends PanelContainer

const SCENE := "res://scenes/shell/taskbar.tscn"
const HEIGHT := 34.0

const PANES := [
	{"id": "profile", "name": "Me", "icon": Icon.Kind.PERSON},
	{"id": "feed", "name": "Feed", "icon": Icon.Kind.SPEECH},
	{"id": "today", "name": "Today", "icon": Icon.Kind.CLOCK},
]

var clock: Label
var meter: Meter
var eye: Icon

var _pane_buttons: Dictionary = {}


static func make() -> Taskbar:
	return load(SCENE).instantiate()


func _ready() -> void:
	custom_minimum_size.y = HEIGHT
	add_theme_stylebox_override(
		"panel", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED, 4, 3, 4, 3)
	)

	# The row sits in a plain Control rather than straight in the panel, so that
	# what it holds can never set the taskbar's minimum width. It used to: on a
	# phone in portrait the buttons wanted 411 units against a 385 unit screen,
	# and the whole shell was dragged that far off the right edge to suit them.
	var frame := Control.new()
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var row := Style.hbox(4 if AppShell.narrow else 6)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(row)
	row.add_child(_start_button())
	row.add_child(Style.vline())
	if AppShell.narrow:
		for p: Dictionary in PANES:
			row.add_child(_pane_button(p))
	else:
		row.add_child(_window_button())
	row.add_child(Style.grow())
	row.add_child(_tray())


func mark_pane(id: String) -> void:
	for key: String in _pane_buttons:
		(_pane_buttons[key] as Tappable).set_selected(key == id)


func refresh(heat: float) -> void:
	clock.text = ("day %d" % Game.day) if AppShell.narrow else (
		"%s · day %d" % [Game.day_name(), Game.day]
	)
	meter.set_value(Game.day_fraction())
	eye.color = Style.ALARM if heat >= 0.5 else Style.INK_FAINT


static func _start_button() -> Control:
	var start := Tappable.new(Vector4(8, 3, 10, 4))
	var row := Style.hbox(6)
	var flag := SpriteAnim.make("fire", 17.0)
	flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(flag)
	row.add_child(Style.label("Start", Style.ui_b, 14, Style.INK))
	start.add_content(row)
	start.pressed.connect(StartMenu.toggle)
	return start


func _pane_button(p: Dictionary) -> Control:
	var id := String(p["id"])
	var task := Tappable.new(Vector4(6, 3, 7, 4), Tappable.Look.LIST)
	var row := Style.hbox(5)
	var glyph := Icon.new(p["icon"], 13, Style.INK)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)
	row.add_child(Style.label(String(p["name"]), Style.ui_b, 13, Style.INK))
	task.add_content(row)
	task.pressed.connect(func() -> void: AppShell.i.show_pane(id))
	_pane_buttons[id] = task
	return task


static func _window_button() -> Control:
	var task := Tappable.new(Vector4(8, 3, 10, 4), Tappable.Look.FLAT)
	var row := Style.hbox(6)
	var glyph := Icon.new(Icon.Kind.FOLDER, 14, Style.INK)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)
	row.add_child(Style.label("ForReals", Style.ui_r, 13, Style.INK))
	task.add_content(row)
	task.custom_minimum_size.x = 150
	return task


func _tray() -> Control:
	var tray := PanelContainer.new()
	tray.add_theme_stylebox_override(
		"panel", Style.box(Style.SURFACE, BevelBox.Style3D.SUNKEN, 7, 3, 8, 3)
	)
	var row := Style.hbox(8)

	eye = Icon.new(Icon.Kind.EYE, 15, Style.INK_FAINT)
	eye.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(eye)

	# Hidden rather than left out, so refresh() still has something to talk to and
	# a hidden child costs an HBoxContainer no width. The Today pane already opens
	# with this same meter, so a phone loses nothing by dropping it here.
	meter = Meter.new(1.0, Style.BAR_FILL, 88, 14)
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meter.visible = not AppShell.narrow
	row.add_child(meter)

	clock = Style.label("day 1", Style.ui_r, 13, Style.INK)
	clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(clock)

	tray.add_child(row)
	return tray
