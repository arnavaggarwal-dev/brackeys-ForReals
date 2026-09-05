class_name Dialog
extends Control

const SCENE := "res://scenes/shell/dialog.tscn"

static var _open: Dialog = null

@onready var frame: PanelContainer = $Frame
@onready var client: VBoxContainer = $Frame/Column/Scroll/Pad/Body
@onready var footer: VBoxContainer = $Frame/Column/FooterPad/Footer

@onready var _dim: ColorRect = $Dim
@onready var _bar: PanelContainer = $Frame/Column/TitleBar
@onready var _title: Label = $Frame/Column/TitleBar/Bar/Title
@onready var _close_slot: HBoxContainer = $Frame/Column/TitleBar/Bar/CloseSlot
@onready var _pad: MarginContainer = $Frame/Column/Scroll/Pad
@onready var _footer_pad: MarginContainer = $Frame/Column/FooterPad

var title := ""
var width := 640.0
var dim := true
var on_close := Callable()


static func open(
	dialog_title: String, dialog_width: float = 640.0, closer: Callable = Callable(),
	dimmed: bool = true
) -> VBoxContainer:
	var node: Dialog = load(SCENE).instantiate()
	node.title = dialog_title
	node.width = dialog_width
	node.on_close = closer
	node.dim = dimmed
	AppShell.i.mount_veil(node)
	_open = node
	Sfx.tick()
	return node.client


static func actions(row: Control) -> void:
	if _open == null:
		return
	_open.footer.add_child(Style.spacer(10))
	_open.footer.add_child(row)


static func close() -> void:
	_open = null
	if AppShell.i != null:
		AppShell.i.clear_veil()


func _ready() -> void:
	_dim.visible = dim
	_dim.mouse_filter = (
		Control.MOUSE_FILTER_STOP if dim else Control.MOUSE_FILTER_IGNORE
	)
	frame.add_theme_stylebox_override("panel", Style.frame_box(3))
	_bar.add_theme_stylebox_override("panel", Style.title_box(true))

	_title.text = title
	_title.add_theme_font_override("font", Style.ui_b)
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", Style.TITLE_TEXT)

	var x := Tappable.new(Vector4(4, 2, 4, 3))
	x.add_content(Icon.new(Icon.Kind.CLOSE, 11, Style.INK))
	x.custom_minimum_size = Vector2(20, 18)
	x.pressed.connect(func() -> void:
		if on_close.is_valid():
			on_close.call()
		else:
			close())
	_close_slot.add_child(x)

	_fit()


# A dialog is sized to what it holds, up to what the viewport can spare.
func _fit() -> void:
	await get_tree().process_frame
	if not is_instance_valid(frame):
		return
	var vp := get_viewport_rect().size
	var chrome := _bar.get_combined_minimum_size().y \
		+ _footer_pad.get_combined_minimum_size().y + 12.0
	var wanted := _pad.get_combined_minimum_size().y + chrome
	var want_size := Vector2(
		minf(width, vp.x - 32.0),
		clampf(wanted, 120.0, vp.y - 32.0)
	)
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.size = want_size
	# A container is never smaller than what it holds, so the width above is a
	# request, not a promise. Centre on what it will actually be, and never on a
	# negative offset, or an oversized dialog walks off the left of the screen.
	var actual := frame.get_combined_minimum_size().max(want_size)
	frame.position = Vector2(
		maxf(0.0, (vp.x - actual.x) * 0.5), maxf(0.0, (vp.y - actual.y) * 0.5)
	).floor()


static func buttons() -> HBoxContainer:
	var row := Style.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_END
	return row


static func button(text: String, wide: bool = false, ink: Color = Style.INK) -> Tappable:
	var t := Tappable.new(Vector4(16, 6, 16, 7))
	var l := Style.label(text, Style.ui_m, 14, ink)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_content(l)
	t.custom_minimum_size.x = 150.0 if wide else 86.0
	return t


static func well(pad: int = 10) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, pad, pad, pad, pad)
	)
	return p


static func message(kind: Icon.Kind, text: String, ink: Color = Style.INK) -> Control:
	var row := Style.hbox(14)
	var glyph := Icon.new(kind, 32, ink)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(glyph)
	row.add_child(Style.body(text, Style.ui_r, 14, Style.INK, 5))
	return row
