class_name WinWindow
extends PanelContainer

var client: VBoxContainer
var title_label: Label

var _title_panel: PanelContainer
var _active := true


func _init(title: String, sunken_client: bool = false) -> void:
	add_theme_stylebox_override("panel", Style.frame_box(3))
	var col := Style.vbox(0)
	add_child(col)

	_title_panel = PanelContainer.new()
	_title_panel.add_theme_stylebox_override("panel", Style.title_box(true))
	var bar := Style.hbox(0)
	_title_panel.add_child(bar)

	title_label = Style.label(title, Style.ui_b, 13, Style.TITLE_TEXT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(title_label)

	var buttons := Style.hbox(2)
	buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buttons.add_child(_title_button(Icon.Kind.MINIMISE))
	buttons.add_child(_title_button(Icon.Kind.MAXIMISE))
	buttons.add_child(_title_button(Icon.Kind.CLOSE))
	bar.add_child(buttons)

	col.add_child(_title_panel)
	col.add_child(Style.spacer(2))

	var body := PanelContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_stylebox_override(
		"panel",
		Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 3, 3, 3, 3) if sunken_client
			else Style.box(Style.SURFACE, BevelBox.Style3D.FLAT, 2, 2, 2, 2)
	)
	client = Style.vbox(0)
	client.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(client)
	col.add_child(body)


func set_active(v: bool) -> void:
	if _active == v:
		return
	_active = v
	_title_panel.add_theme_stylebox_override("panel", Style.title_box(v))
	title_label.add_theme_color_override(
		"font_color", Style.TITLE_TEXT if v else Style.TITLE_TEXT_OFF
	)


static func _title_button(kind: Icon.Kind) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(
		"panel", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED, 3, 2, 3, 2)
	)
	p.custom_minimum_size = Vector2(18, 16)
	var glyph := Icon.new(kind, 10, Style.INK)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(glyph)
	return p
