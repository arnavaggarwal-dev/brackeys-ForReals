class_name Toast
extends PanelContainer

const SCENE := "res://scenes/widgets/toast.tscn"

const SCALE := 1.15
const WIDTH := 300.0
const LIFETIME := 3.6

@export var title := ""
@export var sub := ""
@export var bad := false


static func make(title_text: String, sub_text: String, is_bad: bool) -> Toast:
	var node: Toast = load(SCENE).instantiate()
	node.title = title_text
	node.sub = sub_text
	node.bad = is_bad
	return node


static func px(n: int) -> int:
	return int(round(n * SCALE))


func _ready() -> void:
	add_theme_stylebox_override(
		"panel", Style.box(Style.SURFACE, BevelBox.Style3D.RAISED, 3, 3, 3, 3)
	)
	custom_minimum_size.x = int(WIDTH * SCALE)

	var col := Style.vbox(0)
	col.add_child(_title_bar())
	col.add_child(Style.margins(_body(), px(8), px(7), px(8), px(8)))
	add_child(col)

	_ignore_mouse(self)

	await get_tree().create_timer(LIFETIME).timeout
	queue_free()


func _title_bar() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", Style.title_box(true))
	var row := Style.hbox(6)
	var glyph := Icon.new(
		Icon.Kind.WARNING if bad else Icon.Kind.SPEECH, px(12), Style.TITLE_TEXT
	)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)
	row.add_child(Style.label(
		"Warning" if bad else "ForReals", Style.ui_b, px(12), Style.TITLE_TEXT
	))
	bar.add_child(row)
	return bar


func _body() -> Control:
	var inner := Style.vbox(3)
	inner.add_child(Style.body(title, Style.ui_m, px(13), Style.ALARM if bad else Style.INK))
	if sub != "":
		var line := Style.num(sub, px(10), Style.INK_SOFT)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner.add_child(line)
	return inner


static func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
