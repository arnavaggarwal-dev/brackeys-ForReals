class_name BevelBox
extends StyleBox

enum Style3D {
	RAISED,
	PRESSED,
	SUNKEN,
	GROOVE,
	FLAT,
}

const WHITE := Color("ffffff")
const LIGHT := Color("dfdfdf")
const SHADOW := Color("808080")
const BLACK := Color("0a0a0a")

var bg_color: Color = Color("c0c0c0"):
	set(v):
		bg_color = v
		emit_changed()

var style: Style3D = Style3D.RAISED:
	set(v):
		style = v
		emit_changed()

var border_color: Color = Color(0, 0, 0, 0):
	set(v):
		border_color = v
		emit_changed()
var border_width_left := 0
var border_width_top := 0
var border_width_right := 0
var border_width_bottom := 0
var corner_radius := 0.0


func _init(fill: Color = Color("c0c0c0"), s: Style3D = Style3D.RAISED) -> void:
	bg_color = fill
	style = s


func set_border_width_all(_w: int) -> void:
	pass


func set_corner_radius_all(_r: int) -> void:
	pass


func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect


func _draw(ci: RID, rect: Rect2) -> void:
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return

	if bg_color.a > 0.0:
		RenderingServer.canvas_item_add_rect(ci, rect, bg_color)

	match style:
		Style3D.FLAT:
			return
		Style3D.GROOVE:
			_ring(ci, rect, 0, SHADOW, WHITE)
		Style3D.RAISED:
			_ring(ci, rect, 0, WHITE, BLACK)
			_ring(ci, rect, 1, LIGHT, SHADOW)
		Style3D.PRESSED:
			_ring(ci, rect, 0, BLACK, WHITE)
			_ring(ci, rect, 1, SHADOW, LIGHT)
		Style3D.SUNKEN:
			_ring(ci, rect, 0, SHADOW, WHITE)
			_ring(ci, rect, 1, BLACK, LIGHT)


func _ring(ci: RID, rect: Rect2, inset: int, tl: Color, br: Color) -> void:
	var r := rect.grow(-float(inset))
	if r.size.x < 1.0 or r.size.y < 1.0:
		return
	RenderingServer.canvas_item_add_rect(
		ci, Rect2(r.position.x, r.end.y - 1.0, r.size.x, 1.0), br
	)
	RenderingServer.canvas_item_add_rect(
		ci, Rect2(r.end.x - 1.0, r.position.y, 1.0, r.size.y), br
	)
	RenderingServer.canvas_item_add_rect(
		ci, Rect2(r.position.x, r.position.y, r.size.x - 1.0, 1.0), tl
	)
	RenderingServer.canvas_item_add_rect(
		ci, Rect2(r.position.x, r.position.y, 1.0, r.size.y - 1.0), tl
	)
