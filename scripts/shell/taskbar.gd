class_name Taskbar
extends PanelContainer

const SCENE := "res://scenes/shell/taskbar.tscn"
const HEIGHT := 34.0

const PANES := [
	{"id": "profile", "name": "Me", "icon": Icon.Kind.PERSON},
	{"id": "feed", "name": "Feed", "icon": Icon.Kind.SPEECH},
	{"id": "today", "name": "Today", "icon": Icon.Kind.CLOCK},
]

@onready var clock: Label = $Frame/Row/Tray/TrayRow/Clock
@onready var meter: Meter = $Frame/Row/Tray/TrayRow/DayMeter
@onready var eye: Icon = $Frame/Row/Tray/TrayRow/Eye

@onready var _row: HBoxContainer = $Frame/Row
@onready var _start_slot: HBoxContainer = $Frame/Row/StartSlot
@onready var _tasks: HBoxContainer = $Frame/Row/Tasks
@onready var _tray: PanelContainer = $Frame/Row/Tray

var _pane_buttons: Dictionary = {}


func _ready() -> void:
	add_theme_stylebox_override(
		"panel", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED, 4, 3, 4, 3)
	)
	_tray.add_theme_stylebox_override(
		"panel", Style.box(Style.SURFACE, BevelBox.Style3D.SUNKEN, 7, 3, 8, 3)
	)
	clock.add_theme_font_override("font", Style.ui_r)
	clock.add_theme_font_size_override("font_size", 13)
	clock.add_theme_color_override("font_color", Style.INK)
	rebuild()


func rebuild() -> void:
	_pane_buttons.clear()
	for slot: HBoxContainer in [_start_slot, _tasks]:
		for c in slot.get_children():
			slot.remove_child(c)
			c.queue_free()

	_row.add_theme_constant_override("separation", 4 if AppShell.narrow else 6)
	_start_slot.add_child(_start_button())
	if AppShell.narrow:
		for p: Dictionary in PANES:
			_tasks.add_child(_pane_button(p))
	else:
		_tasks.add_child(_window_button())
	meter.visible = not AppShell.narrow


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
