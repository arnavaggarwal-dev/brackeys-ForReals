class_name Meter
extends Control

const BLOCK_W := 8.0
const BLOCK_GAP := 2.0

var value := 0.0
var ink := Color("000080")
var source: Callable


func _init(v: float = 0.0, color: Color = Color("000080"), w: float = 0.0, h: float = 18.0) -> void:
	value = clampf(v, 0.0, 1.0)
	ink = color
	custom_minimum_size = Vector2(w, h)
	if w <= 0.0:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func follow(fn: Callable) -> Meter:
	source = fn
	set_process(true)
	return self


func _process(_delta: float) -> void:
	if source.is_valid():
		set_value(source.call())


func set_value(v: float) -> void:
	var next := clampf(v, 0.0, 1.0)
	if _blocks(next) != _blocks(value):
		value = next
		queue_redraw()
	else:
		value = next


func _blocks(v: float) -> int:
	var slots := int((size.x - 4.0) / (BLOCK_W + BLOCK_GAP))
	return int(floor(v * slots))


func _draw() -> void:
	if size.x < 6.0 or size.y < 6.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Style.FIELD)
	draw_rect(Rect2(0, 0, size.x - 1, 1), Style.SHADOW)
	draw_rect(Rect2(0, 0, 1, size.y - 1), Style.SHADOW)
	draw_rect(Rect2(0, size.y - 1, size.x, 1), Style.WHITE)
	draw_rect(Rect2(size.x - 1, 0, 1, size.y), Style.WHITE)

	var slots := int((size.x - 4.0) / (BLOCK_W + BLOCK_GAP))
	var filled := int(floor(value * slots))
	for i in filled:
		draw_rect(
			Rect2(2.0 + i * (BLOCK_W + BLOCK_GAP), 2.0, BLOCK_W, size.y - 4.0),
			ink
		)
