class_name EtchedRule
extends Control

var vertical := false


func _init(upright: bool = false) -> void:
	vertical = upright
	if vertical:
		custom_minimum_size.x = 2
		size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		custom_minimum_size.y = 2
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if vertical:
		var x := floorf(size.x * 0.5) - 1.0
		draw_rect(Rect2(x, 0, 1, size.y), Style.SHADOW)
		draw_rect(Rect2(x + 1, 0, 1, size.y), Style.WHITE)
	else:
		var y := floorf(size.y * 0.5) - 1.0
		draw_rect(Rect2(0, y, size.x, 1), Style.SHADOW)
		draw_rect(Rect2(0, y + 1, size.x, 1), Style.WHITE)
