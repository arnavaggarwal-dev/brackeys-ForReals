class_name EtchedRule
extends Control

@export var vertical := false:
	set(v):
		vertical = v
		_apply()


static func make(upright: bool = false) -> EtchedRule:
	var r := EtchedRule.new()
	r.vertical = upright
	return r


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply()


func _apply() -> void:
	if vertical:
		custom_minimum_size = Vector2(2, 0)
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	else:
		custom_minimum_size = Vector2(0, 2)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
	queue_redraw()


func _draw() -> void:
	if vertical:
		var x := floorf(size.x * 0.5) - 1.0
		draw_rect(Rect2(x, 0, 1, size.y), Style.SHADOW)
		draw_rect(Rect2(x + 1, 0, 1, size.y), Style.WHITE)
	else:
		var y := floorf(size.y * 0.5) - 1.0
		draw_rect(Rect2(0, y, size.x, 1), Style.SHADOW)
		draw_rect(Rect2(0, y + 1, size.x, 1), Style.WHITE)
