class_name Tappable
extends PanelContainer

signal pressed

enum Look {
	BUTTON,
	LIST,
	FLAT,
	ACTION,
}

const DRAG_SLOP := 10.0

var look: Look = Look.BUTTON
var selected := false

var _box: BevelBox
var _content: MarginContainer
var _pad := Vector4(10, 5, 10, 5)
var _pressed_in := false
var _press_at := Vector2.ZERO
var _enabled := true
var _hovering := false


func _init(pad := Vector4(10, 5, 10, 5), style: Look = Look.BUTTON) -> void:
	_pad = pad
	look = style
	_box = Style.box(Style.SURFACE, BevelBox.Style3D.RAISED)
	add_theme_stylebox_override("panel", _box)

	_content = MarginContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply(false)


func add_content(node: Control) -> void:
	_content.add_child(node)
	_pass_through(node)


func _pass_through(node: Node) -> void:
	if node is Tappable:
		return
	if node is Control and node.mouse_filter == Control.MOUSE_FILTER_STOP:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_pass_through(child)


func set_selected(v: bool) -> void:
	selected = v
	_apply(_pressed_in)


func is_enabled() -> bool:
	return _enabled


func set_enabled(v: bool) -> void:
	_enabled = v
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if v else Control.CURSOR_ARROW
	)
	_apply(false)


func _apply(down: bool) -> void:
	var l := int(_pad.x)
	var t := int(_pad.y)
	var r := int(_pad.z)
	var b := int(_pad.w)

	match look:
		Look.BUTTON:
			_box.style = BevelBox.Style3D.PRESSED if down else BevelBox.Style3D.RAISED
			_box.bg_color = Style.SURFACE
		Look.LIST:
			_box.style = BevelBox.Style3D.FLAT
			if selected:
				_box.bg_color = Style.SELECT_BG
			elif _hovering and _enabled:
				_box.bg_color = Style.SURFACE_HI
			else:
				_box.bg_color = Style.FIELD
		Look.ACTION:
			if not _enabled:
				_box.style = BevelBox.Style3D.FLAT
				_box.bg_color = Color(0, 0, 0, 0)
			elif down:
				_box.style = BevelBox.Style3D.PRESSED
				_box.bg_color = Style.SURFACE
			elif _hovering:
				_box.style = BevelBox.Style3D.RAISED
				_box.bg_color = Style.SURFACE_HI
			else:
				_box.style = BevelBox.Style3D.GROOVE
				_box.bg_color = Color(0, 0, 0, 0)
		Look.FLAT:
			_box.style = BevelBox.Style3D.PRESSED if down else (
				BevelBox.Style3D.RAISED if (_hovering and _enabled) else BevelBox.Style3D.FLAT
			)
			_box.bg_color = Style.SURFACE if (_hovering or down) else Color(0, 0, 0, 0)

	var nudge := 1 if (down and look != Look.LIST) else 0
	_content.add_theme_constant_override("margin_left", l + nudge)
	_content.add_theme_constant_override("margin_top", t + nudge)
	_content.add_theme_constant_override("margin_right", r - nudge)
	_content.add_theme_constant_override("margin_bottom", b - nudge)


func _refuse(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		Sfx.buzz(0.12)
	accept_event()


func _notification(what: int) -> void:
	if not _enabled:
		return
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovering = true
		_apply(_pressed_in)
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovering = false
		_pressed_in = false
		_apply(false)


func _gui_input(event: InputEvent) -> void:
	if not _enabled:
		_refuse(event)
		return

	if event is InputEventScreenDrag:
		_drop_if_dragged(event.position)
		return

	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var down: bool = event.pressed
	var up: bool = not event.pressed

	if down:
		_pressed_in = true
		_press_at = event.position
		_apply(true)
		accept_event()
	elif up and _pressed_in:
		_pressed_in = false
		_apply(false)
		accept_event()
		if DragScroll.scrolling:
			return
		Sfx.tap()
		pressed.emit()


func _drop_if_dragged(at: Vector2) -> void:
	if not _pressed_in or at.distance_to(_press_at) < DRAG_SLOP:
		return
	_pressed_in = false
	_apply(false)
