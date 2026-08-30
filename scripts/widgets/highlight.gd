class_name Highlight
extends Control

const THICK := 3.0

var phase := 0.0


func _process(delta: float) -> void:
	phase += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.55 + 0.45 * absf(sin(phase * 3.0))
	var c := Style.HOT
	c.a = pulse
	draw_rect(Rect2(Vector2.ZERO, size), c, false, THICK)
	var tick := 10.0
	var corners := [
		Vector2(0, 0), Vector2(size.x, 0), Vector2(0, size.y), Vector2(size.x, size.y)
	]
	for p: Vector2 in corners:
		var dx := tick if p.x < size.x * 0.5 else -tick
		var dy := tick if p.y < size.y * 0.5 else -tick
		draw_line(p, p + Vector2(dx, 0), c, THICK)
		draw_line(p, p + Vector2(0, dy), c, THICK)
