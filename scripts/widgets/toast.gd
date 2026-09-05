class_name Toast
extends PanelContainer

const SCENE := "res://scenes/widgets/toast.tscn"

const SCALE := 1.15
const WIDTH := 300.0
const LIFETIME := 3.6

@export var title := ""
@export var sub := ""
@export var bad := false

@onready var _bar: PanelContainer = $Column/TitleBar
@onready var _bar_icon: Icon = $Column/TitleBar/Bar/Glyph
@onready var _bar_label: Label = $Column/TitleBar/Bar/Kind
@onready var _pad: MarginContainer = $Column/Pad
@onready var _title_label: Label = $Column/Pad/Lines/Title
@onready var _sub_label: Label = $Column/Pad/Lines/Sub


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

	_bar.add_theme_stylebox_override("panel", Style.title_box(true))
	_bar_icon.kind = Icon.Kind.WARNING if bad else Icon.Kind.SPEECH
	_bar_icon.color = Style.TITLE_TEXT
	_bar_icon.custom_minimum_size = Vector2.ONE * px(12)

	_style(_bar_label, Style.ui_b, px(12), Style.TITLE_TEXT)
	_bar_label.text = "Warning" if bad else "ForReals"

	for side: Array in [["margin_left", px(8)], ["margin_top", px(7)],
			["margin_right", px(8)], ["margin_bottom", px(8)]]:
		_pad.add_theme_constant_override(String(side[0]), int(side[1]))

	_style(_title_label, Style.ui_m, px(13), Style.ALARM if bad else Style.INK)
	_title_label.text = title

	_sub_label.visible = sub != ""
	_style(_sub_label, Style.tracked(Style.tiny_b, 1), px(10), Style.INK_SOFT)
	_sub_label.text = sub

	_ignore_mouse(self)

	await get_tree().create_timer(LIFETIME).timeout
	queue_free()


static func _style(l: Label, font: Font, size: int, color: Color) -> void:
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)


static func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
