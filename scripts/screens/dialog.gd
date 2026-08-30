class_name Dialog
extends RefCounted

static var _open: Control = null
static var _footer: VBoxContainer = null


static func open(
	title: String, width: float = 640.0, on_close: Callable = Callable(),
	dim: bool = true
) -> VBoxContainer:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	if dim:
		var veil := ColorRect.new()
		veil.color = Color(0, 0, 0, 0.35)
		veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		veil.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(veil)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", Style.frame_box(3))
	root.add_child(frame)

	var col := Style.vbox(0)
	frame.add_child(col)

	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", Style.title_box(true))
	var bar_row := Style.hbox(0)
	bar_row.add_child(Style.label(title, Style.ui_b, 14, Style.TITLE_TEXT))
	bar_row.add_child(Style.grow())

	var x := Tappable.new(Vector4(4, 2, 4, 3))
	x.add_content(Icon.new(Icon.Kind.CLOSE, 11, Style.INK))
	x.custom_minimum_size = Vector2(20, 18)
	x.pressed.connect(func() -> void:
		if on_close.is_valid():
			on_close.call()
		else:
			close())
	bar_row.add_child(x)
	bar.add_child(bar_row)
	col.add_child(bar)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	AppShell.i.style_scrollbar(scroll.get_v_scroll_bar())
	col.add_child(scroll)

	var client := Style.vbox(0)
	client.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := Style.margins(client, 12, 12, 12, 12)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pad)

	var footer := Style.vbox(0)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var footer_pad := Style.margins(footer, 12, 0, 12, 12)
	footer_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(footer_pad)
	_footer = footer

	AppShell.i.mount_veil(root)
	_open = root
	Sfx.tick()
	_fit(frame, bar, pad, footer_pad, width)
	return client


static func actions(row: Control) -> void:
	if _footer == null:
		return
	_footer.add_child(Style.spacer(10))
	_footer.add_child(row)


static func _fit(
	frame: PanelContainer, bar: PanelContainer, pad: Control, footer: Control,
	want_w: float
) -> void:
	await AppShell.i.get_tree().process_frame
	if not is_instance_valid(frame):
		return
	var vp := AppShell.i.get_viewport_rect().size
	var chrome := bar.get_combined_minimum_size().y 		+ footer.get_combined_minimum_size().y + 12.0
	var wanted := pad.get_combined_minimum_size().y + chrome
	var size := Vector2(
		minf(want_w, vp.x - 32.0),
		clampf(wanted, 120.0, vp.y - 32.0)
	)
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.size = size
	frame.position = ((vp - size) * 0.5).floor()


static func close() -> void:
	_open = null
	_footer = null
	if AppShell.i != null:
		AppShell.i.clear_veil()


static func buttons() -> HBoxContainer:
	var row := Style.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_END
	return row


static func button(text: String, wide: bool = false, ink: Color = Style.INK) -> Tappable:
	var t := Tappable.new(Vector4(16, 6, 16, 7))
	var l := Style.label(text, Style.ui_m, 14, ink)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_content(l)
	t.custom_minimum_size.x = 150.0 if wide else 86.0
	return t


static func well(pad: int = 10) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, pad, pad, pad, pad)
	)
	return p


static func message(kind: Icon.Kind, text: String, ink: Color = Style.INK) -> Control:
	var row := Style.hbox(14)
	var glyph := Icon.new(kind, 32, ink)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(glyph)
	row.add_child(Style.body(text, Style.ui_r, 14, Style.INK, 5))
	return row
