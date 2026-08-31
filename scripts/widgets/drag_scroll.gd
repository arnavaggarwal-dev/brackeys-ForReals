class_name DragScroll
extends Node

const SLOP := 10.0

static var scrolling := false

var _host: ScrollContainer
var _tracking := false
var _from := Vector2.ZERO
var _start := 0


static func attach(host: ScrollContainer) -> void:
	var d := DragScroll.new()
	d._host = host
	host.add_child(d)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin(event.position)
		else:
			_tracking = false
		return
	if event is InputEventScreenDrag:
		_move(event.position)
		return

	if not DisplayServer.is_touchscreen_available():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin(event.position)
		else:
			_tracking = false
	elif event is InputEventMouseMotion and _tracking:
		_move(event.position)


func _begin(at: Vector2) -> void:
	scrolling = false
	_tracking = _host.get_global_rect().has_point(at)
	if not _tracking:
		return
	_from = at
	_start = _host.scroll_vertical


func _move(at: Vector2) -> void:
	if not _tracking:
		return
	var travelled := at.y - _from.y
	if not scrolling and absf(travelled) < SLOP:
		return
	scrolling = true
	_host.scroll_vertical = _start - int(travelled)
	get_viewport().set_input_as_handled()
