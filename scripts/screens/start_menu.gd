class_name StartMenu
extends Control

const SCENE := "res://scenes/shell/start_menu.tscn"
const WIDTH := 236.0

static var _open := false

@onready var _frame: PanelContainer = $Frame
@onready var _spine: PanelContainer = $Frame/Row/Spine
@onready var _spine_label: Label = $Frame/Row/Spine/Letters
@onready var _items: VBoxContainer = $Frame/Row/Items


static func is_open() -> bool:
	return _open


static func toggle() -> void:
	if _open:
		close()
	else:
		show_menu()


static func close() -> void:
	if not _open:
		return
	_open = false
	AppShell.i.clear_menu()


static func show_menu() -> void:
	_open = true
	AppShell.i.mount_menu(load(SCENE).instantiate())
	Sfx.tick()


func _ready() -> void:
	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close())

	_frame.add_theme_stylebox_override("panel", Style.frame_box(3))
	_frame.offset_bottom = -(AppShell.TASKBAR_H + 2.0)
	_frame.custom_minimum_size.x = WIDTH

	_spine.add_theme_stylebox_override("panel", Style.plain_box(Style.TITLE_A))
	var letters := PackedStringArray()
	for c in "ForReals":
		letters.append(c)
	_spine_label.text = "\n".join(letters)
	_spine_label.add_theme_font_override("font", Style.ui_b)
	_spine_label.add_theme_font_size_override("font_size", 13)
	_spine_label.add_theme_color_override("font_color", Style.TITLE_TEXT)

	_add(Icon.Kind.SPEECH,
		"Sound: on" if not Sfx.muted else "Sound: off",
		"every click, tick and boom" if not Sfx.muted else "nothing makes a noise",
		func() -> void:
			Sfx.set_muted(not Sfx.muted)
			close()
			show_menu()
	)
	_add(Icon.Kind.PERSON,
		"Font: %s" % Style.face_name(),
		"the whole interface, in a different face",
		func() -> void:
			var nxt := Style.next_face()
			Style.set_face(nxt)
			Prefs.set_v("face", nxt)
			close()
			Game.nav_dirty.emit()
			Game.view_dirty.emit()
			show_menu()
	)
	_add(Icon.Kind.CHECK, "Tutorial", "the arrows again, from the top",
		func() -> void:
			close()
			if Game.screen == "app":
				Tutorial.start()
			else:
				Game.toast_requested.emit(
					"Not yet", "sign in first and it will run itself", true
				)
	)
	_add(Icon.Kind.WARNING, "Nuke account...", "delete the save, permanently",
		func() -> void:
			close()
			NukeScreen.confirm(),
		Style.ALARM
	)
	_add(Icon.Kind.CLOSE, "Quit", "saves first, then closes",
		func() -> void:
			close()
			AppShell.i.quit_game()
	)


func _add(
	kind: Icon.Kind, title: String, note: String, on_press: Callable,
	ink: Color = Style.INK
) -> void:
	if _items.get_child_count() > 0:
		_items.add_child(Style.hline())

	var t := Tappable.new(Vector4(10, 8, 12, 9), Tappable.Look.LIST)
	var row := Style.hbox(10)

	var glyph := Icon.new(kind, 16, ink)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)

	var col := Style.vbox(1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(Style.label(title, Style.ui_b, 14, ink))
	col.add_child(Style.num(note, 9, Style.INK_FAINT))
	row.add_child(col)

	t.add_content(row)
	t.pressed.connect(on_press)
	_items.add_child(t)
