class_name Taskbar
extends PanelContainer

const SCENE := "res://scenes/shell/taskbar.tscn"
const HEIGHT := 34.0

var clock: Label
var meter: Meter
var eye: Icon


static func make() -> Taskbar:
	return load(SCENE).instantiate()


func _ready() -> void:
	custom_minimum_size.y = HEIGHT
	add_theme_stylebox_override(
		"panel", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED, 4, 3, 4, 3)
	)

	var row := Style.hbox(6)
	add_child(row)
	row.add_child(_start_button())
	row.add_child(Style.vline())
	row.add_child(_window_button())
	row.add_child(Style.grow())
	row.add_child(_tray())


func refresh(heat: float) -> void:
	clock.text = "%s · day %d" % [Game.day_name(), Game.day]
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

	meter = Meter.new(1.0, Style.BAR_FILL, 88, 14)
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(meter)

	clock = Style.label("day 1", Style.ui_r, 13, Style.INK)
	clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(clock)

	tray.add_child(row)
	return tray
