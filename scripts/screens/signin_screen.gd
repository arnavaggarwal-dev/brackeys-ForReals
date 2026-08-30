class_name SignInScreen
extends RefCounted

static var _handle := ""
static var _avatar := 0
static var _agreed := false


static func show_signin() -> void:
	if _handle == "":
		_handle = Data.SUGGESTED_HANDLES[randi() % Data.SUGGESTED_HANDLES.size()]

	var body := Dialog.open("Connect to ForReals Network", 560.0, show_signin, false)

	body.add_child(Dialog.message(
		Icon.Kind.PERSON,
		"Enter a name for this account. It cannot be changed later, and it will "
		+ "be shown on everything you post."
	))
	body.add_child(Style.spacer(16))

	body.add_child(Style.group("Account name", _handle_field()))
	body.add_child(Style.spacer(16))
	body.add_child(Style.group("Picture", _avatar_row()))
	body.add_child(Style.spacer(16))
	body.add_child(_agree_row())
	body.add_child(Style.spacer(6))
	body.add_child(Style.hline())
	body.add_child(Style.spacer(12))

	var rules := Style.body(
		"One post a day. Your feed is empty until you follow somebody, and every "
		+ "follow costs you part of that day, and only that day.",
		Style.ui_r, 12, Style.INK_SOFT, 4
	)
	body.add_child(rules)
	body.add_child(Style.spacer(14))

	var row := Dialog.buttons()
	var ok := Dialog.button("OK")
	ok.set_enabled(_agreed)
	ok.pressed.connect(_start)
	row.add_child(ok)

	var cancel := Dialog.button("Cancel")
	cancel.pressed.connect(func() -> void:
		Game.toast_requested.emit("There is nothing else on this machine.", "", false))
	row.add_child(cancel)
	Dialog.actions(row)


static func _handle_field() -> Control:
	var row := Style.hbox(8)
	row.add_child(Style.label("@", Style.ui_b, 16, Style.INK_SOFT))

	var field := PanelContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 5, 4, 5, 5)
	)

	var input := LineEdit.new()
	input.text = _handle
	input.max_length = 18
	input.flat = true
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_font_override("font", Style.ui_r)
	input.add_theme_font_size_override("font_size", 15)
	input.add_theme_color_override("font_color", Style.INK)
	input.add_theme_color_override("caret_color", Style.INK)
	input.add_theme_color_override("selection_color", Style.SELECT_BG)
	input.text_changed.connect(func(t: String) -> void:
		_handle = t
		Sfx.keypress())
	field.add_child(input)
	row.add_child(field)

	var dice := Dialog.button("Suggest")
	dice.pressed.connect(func() -> void:
		_handle = Data.SUGGESTED_HANDLES[randi() % Data.SUGGESTED_HANDLES.size()]
		show_signin())
	row.add_child(dice)
	return row


static func _avatar_row() -> Control:
	var well := Dialog.well(5)
	var row := Style.hbox(5)
	for i in Data.AVATAR_CHOICES.size():
		var choice: Dictionary = Data.AVATAR_CHOICES[i]
		var cell := Tappable.new(Vector4(4, 4, 4, 4), Tappable.Look.LIST)
		cell.set_selected(i == _avatar)
		cell.add_content(Avatar.choice(choice, 34))
		var index := i
		cell.pressed.connect(func() -> void:
			_avatar = index
			show_signin())
		row.add_child(cell)
	well.add_child(row)
	return well


static func _agree_row() -> Control:
	var t := Tappable.new(Vector4(2, 2, 2, 2), Tappable.Look.FLAT)
	var row := Style.hbox(9)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 2, 2, 2, 2)
	)
	box.custom_minimum_size = Vector2(17, 17)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(Icon.new(
		Icon.Kind.CHECK, 12, Style.INK if _agreed else Color(0, 0, 0, 0)
	))
	row.add_child(box)
	row.add_child(Style.body(
		"I have read the community guidelines.", Style.ui_r, 13,
		Style.INK if _agreed else Style.INK_SOFT, 3
	))
	t.add_content(row)
	t.pressed.connect(func() -> void:
		_agreed = not _agreed
		show_signin())
	return t


static func _start() -> void:
	var name := _handle.strip_edges()
	if name == "":
		name = "someone"
	AppShell.i.clear_veil()
	Game.begin(name, Data.AVATAR_CHOICES[_avatar])
	Sfx.blip()
	Game.toast_requested.emit("Welcome, @%s" % name, "you have one post a day. spend it well", false)
