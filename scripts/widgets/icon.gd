class_name Icon
extends Control

enum Kind {
	HEART, SPEECH, FLAME, EYE, CHECK, CROSS, DOT, PERSON, CARET_DOWN, PLUS,
	MINIMISE, MAXIMISE, CLOSE, WARNING, STOP, FOLDER, CLOCK,
}

@export var kind: Kind = Kind.DOT:
	set(v):
		kind = v
		queue_redraw()

@export var color: Color = Color.BLACK:
	set(v):
		color = v
		queue_redraw()


func _init(k: Kind = Kind.DOT, px: float = 12.0, c: Color = Color.BLACK) -> void:
	kind = k
	color = c
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _px(x: int, y: int, w: int = 1, h: int = 1, c: Color = Color(0, 0, 0, 0)) -> void:
	var unit := maxf(1.0, floorf(minf(size.x, size.y) / 12.0))
	var origin := ((size - Vector2(12, 12) * unit) * 0.5).floor()
	draw_rect(
		Rect2(origin + Vector2(x, y) * unit, Vector2(w, h) * unit),
		color if c.a == 0.0 else c
	)


func _bitmap(rows: Array) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != " ":
				_px(x, y)


func _draw() -> void:
	if size.x < 3.0 or size.y < 3.0:
		return
	match kind:
		Kind.HEART:
			_bitmap([
				"            ", "  ##   ##   ", " #### #### ", " ######### ",
				" ######### ", "  #######  ", "   #####   ", "    ###    ",
				"     #     ", "           ", "           ", "           ",
			])
		Kind.SPEECH:
			_bitmap([
				"            ", " ######### ", " #       # ", " #       # ",
				" #       # ", " ######### ", "  ##       ", " ##        ",
				"            ", "            ", "            ", "            ",
			])
		Kind.FLAME:
			_bitmap([
				"     #      ", "    ##      ", "   ####     ", "  ## ###    ",
				"  #   ###   ", " ##    ###  ", " ##     ##  ", " ###   ###  ",
				"  ### ####  ", "   ######   ", "    ####    ", "            ",
			])
		Kind.EYE:
			_bitmap([
				"            ", "            ", "   ######   ", " ##      ## ",
				"#   ####   #", "#  ######  #", "#   ####   #", " ##      ## ",
				"   ######   ", "            ", "            ", "            ",
			])
		Kind.CHECK:
			_bitmap([
				"            ", "          # ", "         ## ", "  #     ##  ",
				"  ##   ##   ", "   ## ##    ", "    ###     ", "     #      ",
				"            ", "            ", "            ", "            ",
			])
		Kind.CROSS:
			_bitmap([
				"            ", " ##      ## ", " ###    ### ", "  ###  ###  ",
				"   ######   ", "    ####    ", "   ######   ", "  ###  ###  ",
				" ###    ### ", " ##      ## ", "            ", "            ",
			])
		Kind.DOT:
			_bitmap([
				"            ", "            ", "            ", "    ####    ",
				"   ######   ", "   ######   ", "   ######   ", "    ####    ",
				"            ", "            ", "            ", "            ",
			])
		Kind.PERSON:
			_bitmap([
				"    ####    ", "   ##  ##   ", "   ##  ##   ", "    ####    ",
				"            ", "  ########  ", " ##########", " ##      ## ",
				" ##      ## ", " ##      ## ", "            ", "            ",
			])
		Kind.CARET_DOWN:
			_bitmap([
				"            ", "            ", "            ", " ######### ",
				"  #######   ", "   #####    ", "    ###     ", "     #      ",
				"            ", "            ", "            ", "            ",
			])
		Kind.PLUS:
			_bitmap([
				"            ", "     ##     ", "     ##     ", "     ##     ",
				" ########## ", " ########## ", "     ##     ", "     ##     ",
				"     ##     ", "            ", "            ", "            ",
			])
		Kind.MINIMISE:
			_bitmap([
				"            ", "            ", "            ", "            ",
				"            ", "            ", "            ", "            ",
				"  #######   ", "  #######   ", "            ", "            ",
			])
		Kind.MAXIMISE:
			_bitmap([
				"            ", " ######### ", " ######### ", " #       # ",
				" #       # ", " #       # ", " #       # ", " #       # ",
				" ######### ", "            ", "            ", "            ",
			])
		Kind.CLOSE:
			_bitmap([
				"            ", "            ", "  #      #  ", "  ##    ##  ",
				"   ##  ##   ", "    ####    ", "    ####    ", "   ##  ##   ",
				"  ##    ##  ", "  #      #  ", "            ", "            ",
			])
		Kind.WARNING:
			_bitmap([
				"     ##     ", "     ##     ", "    ####    ", "    #  #    ",
				"   ##  ##   ", "   ## # #   ", "  ##  ##  # ", "  ##  ##  # ",
				" ##       ##", " ##   ##  ##", "############", "            ",
			])
		Kind.STOP:
			_bitmap([
				"    ####    ", "   ######   ", "  ########  ", " ########## ",
				" ########## ", " ########## ", " ########## ", " ########## ",
				"  ########  ", "   ######   ", "    ####    ", "            ",
			])
		Kind.FOLDER:
			_bitmap([
				"            ", "  ####      ", " ###########", " ###########",
				" ##       ##", " ##       ##", " ##       ##", " ###########",
				"            ", "            ", "            ", "            ",
			])
		Kind.CLOCK:
			_bitmap([
				"            ", "   ######   ", " ##      ## ", " #    #   # ",
				"#     #    #", "#     ####  #", "#          #", " #        # ",
				" ##      ## ", "   ######   ", "            ", "            ",
			])
