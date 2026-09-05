class_name TosScreen
extends RefCounted

const PATH := "res://TOS.md"

const FALLBACK := """# Terms of Service

The terms could not be loaded on this machine. By continuing you agree to them
anyway, which is how this has always worked.
"""

static var _read := false


static func show_tos() -> void:
	var body := Dialog.open("ForReals Network - Terms of Service", 720.0, show_tos, true)

	body.add_child(Dialog.message(
		Icon.Kind.FOLDER,
		"Read this before your account is created. It will not be shown again."
	))
	body.add_child(Style.spacer(14))

	var page := PanelContainer.new()
	page.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 14, 12, 14, 14)
	)
	page.add_child(Md.render(_document()))
	body.add_child(page)

	var footer := Style.vbox(10)
	footer.add_child(_read_row())

	var row := Dialog.buttons()
	var ok := Dialog.button("I Agree")
	ok.set_enabled(_read)
	ok.pressed.connect(_accept)
	row.add_child(ok)

	var no := Dialog.button("Decline")
	no.pressed.connect(func() -> void:
		Game.toast_requested.emit(
			"Declining is not available", "there is nothing else on this machine", true
		))
	row.add_child(no)
	footer.add_child(row)
	Dialog.actions(footer)


static func _document() -> String:
	if not FileAccess.file_exists(PATH):
		push_warning("TosScreen: %s is missing from the build" % PATH)
		return FALLBACK
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return FALLBACK
	var text := f.get_as_text()
	f.close()
	return text if text.strip_edges() != "" else FALLBACK


static func _read_row() -> Control:
	var t := Tappable.new(Vector4(2, 2, 2, 2), Tappable.Look.FLAT)
	var row := Style.hbox(9)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 2, 2, 2, 2)
	)
	box.custom_minimum_size = Vector2(17, 17)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(Icon.new(Icon.Kind.CHECK, 12, Style.INK if _read else Color(0, 0, 0, 0)))
	row.add_child(box)
	row.add_child(Style.body(
		"I have read and accept these terms."
			if _read else
		"Tick to accept these terms.",
		Style.ui_r, 13, Style.INK if _read else Style.ALARM, 3
	))
	t.add_content(row)
	t.pressed.connect(func() -> void:
		_read = not _read
		show_tos())
	return t


static func _accept() -> void:
	if not _read:
		return
	Sfx.blip()
	Dialog.close()
	SignInScreen.show_signin()
