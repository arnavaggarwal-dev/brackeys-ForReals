class_name StartMenu
extends RefCounted

const WIDTH := 236.0

static var _open := false


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

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close())

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", Style.frame_box(3))
	frame.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	frame.grow_horizontal = Control.GROW_DIRECTION_END
	frame.grow_vertical = Control.GROW_DIRECTION_BEGIN
	frame.offset_left = 4.0
	frame.offset_bottom = -(AppShell.TASKBAR_H + 2.0)
	frame.custom_minimum_size.x = WIDTH

	var row := Style.hbox(0)
	row.add_child(_spine())

	var items := Style.vbox(0)
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_child(_item(
		Icon.Kind.SPEECH,
		"Sound: on" if not Sfx.muted else "Sound: off",
		"every click, tick and boom" if not Sfx.muted else "nothing makes a noise",
		func() -> void:
			Sfx.set_muted(not Sfx.muted)
			close()
			show_menu()
	))
	items.add_child(Style.hline())
	items.add_child(_item(
		Icon.Kind.PERSON,
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
	))
	items.add_child(Style.hline())
	items.add_child(_item(
		Icon.Kind.CHECK, "Tutorial", "the arrows again, from the top",
		func() -> void:
			close()
			if Game.screen == "app":
				Tutorial.start()
			else:
				Game.toast_requested.emit(
					"Not yet", "sign in first and it will run itself", true
				)
	))
	items.add_child(Style.hline())
	items.add_child(_item(
		Icon.Kind.WARNING, "Nuke account...", "delete the save, permanently",
		func() -> void:
			close()
			NukeScreen.confirm(),
		Style.ALARM
	))
	items.add_child(Style.hline())
	items.add_child(_item(
		Icon.Kind.CLOSE, "Quit", "saves first, then closes",
		func() -> void:
			close()
			AppShell.i.quit_game()
	))
	row.add_child(items)
	frame.add_child(row)
	root.add_child(frame)

	AppShell.i.mount_menu(root)
	Sfx.tick()


static func _spine() -> Control:
	var spine := PanelContainer.new()
	spine.add_theme_stylebox_override("panel", Style.plain_box(Style.TITLE_A))
	spine.custom_minimum_size.x = 26

	var letters := PackedStringArray()
	for c in "ForReals":
		letters.append(c)
	var stacked := "\n".join(letters)
	var label := Style.label(stacked, Style.ui_b, 13, Style.TITLE_TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_constant_override("line_spacing", -2)
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spine.add_child(label)
	return spine


static func _item(
	kind: Icon.Kind, title: String, note: String, on_press: Callable,
	ink: Color = Style.INK
) -> Control:
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
	return t
