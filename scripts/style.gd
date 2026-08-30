extends Node

const DESKTOP     := Color("008080")
const SURFACE     := Color("c0c0c0")
const SURFACE_HI  := Color("dfdfdf")
const WHITE       := Color("ffffff")
const SHADOW      := Color("808080")
const BLACK       := Color("0a0a0a")
const FIELD       := Color("ffffff")

const TITLE_A     := Color("000080")
const TITLE_OFF   := Color("808080")
const TITLE_TEXT  := Color("ffffff")
const TITLE_TEXT_OFF := Color("dfdfdf")

const INK         := Color("0a0a0a")
const INK_SOFT    := Color("404040")
const INK_FAINT   := Color("808080")
const SELECT_BG   := Color("000080")
const SELECT_FG   := Color("ffffff")

const HOT         := Color("000080")
const HOT_LIGHT   := Color("1084d0")
const ALARM       := Color("aa0000")
const ALARM_WASH  := Color("ffdede")
const WARN        := Color("806000")
const OK_GREEN    := Color("008000")
const BAR_FILL    := Color("000080")

const TOPIC_COLORS := {
	"sport":      Color("008000"),
	"war":        Color("800000"),
	"technology": Color("800080"),
	"politics":   Color("000080"),
	"science":    Color("008080"),
	"food":       Color("806000"),
}

var ui_base: FontFile
var ui_r: Font
var ui_m: Font
var ui_b: Font
var tiny_r: FontFile
var tiny_b: FontFile

var _tracked: Dictionary = {}


const FACES := {
	"w95fa": {"path": "res://assets/fonts/W95FA.otf", "name": "Windows 95"},
	"pixel": {"path": "res://assets/fonts/PixelifySans-Regular.ttf", "name": "Blocky"},
}

var face := "w95fa"


func _ready() -> void:
	tiny_r = load("res://assets/fonts/Silkscreen-Regular.ttf")
	tiny_b = load("res://assets/fonts/Silkscreen-Bold.ttf")
	_crisp(tiny_r)
	_crisp(tiny_b)
	set_face(String(Prefs.get_v("face", "w95fa")))


func face_name() -> String:
	return String(FACES[face]["name"])


func next_face() -> String:
	var keys := FACES.keys()
	return String(keys[(keys.find(face) + 1) % keys.size()])


func set_face(id: String) -> void:
	if not FACES.has(id):
		id = "w95fa"
	face = id
	ui_base = load(String(FACES[id]["path"]))
	_crisp(ui_base)
	ui_r = ui_base
	ui_m = _weight(ui_base, 0.35)
	ui_b = _weight(ui_base, 0.85)


func _weight(base: FontFile, amount: float) -> Font:
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_embolden = amount
	return fv


func _crisp(f: FontFile) -> void:
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.hinting = TextServer.HINTING_NONE
	f.force_autohinter = false


func topic_color(id: String) -> Color:
	return TOPIC_COLORS.get(id, INK)


func tracked(base: Font, px: int) -> Font:
	if px == 0 or base == null:
		return base
	var key := "%d_%d" % [base.get_instance_id(), px]
	if _tracked.has(key):
		return _tracked[key]
	var fv := FontVariation.new()
	fv.base_font = base
	fv.spacing_glyph = px
	_tracked[key] = fv
	return fv


func label(text: String, font: Font, size: int, color: Color, track: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", tracked(font, track))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func body(text: String, font: Font, size: int, color: Color, line_spacing: float = 3.0) -> Label:
	var l := label(text, font, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_constant_override("line_spacing", int(line_spacing))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func rich(bb: String, font: Font, size: int, color: Color, line_spacing: float = 4.0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bb
	r.add_theme_font_override("normal_font", font)
	r.add_theme_font_override("bold_font", ui_b)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.add_theme_constant_override("line_separation", int(line_spacing))
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func num(text: String, size: int, color: Color) -> Label:
	return label(text, tiny_b, size, color, 1)


func live(fn: Callable, font: Font, size: int, color: Color, track: int = 0) -> LiveLabel:
	var l := LiveLabel.new(fn)
	l.add_theme_font_override("font", tracked(font, track))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func live_num(fn: Callable, size: int, color: Color) -> LiveLabel:
	return live(fn, tiny_b, size, color, 1)


func box(
	fill: Color, style: BevelBox.Style3D = BevelBox.Style3D.RAISED,
	l: int = 0, t: int = 0, r: int = 0, b: int = 0
) -> BevelBox:
	var sb := BevelBox.new(fill, style)
	sb.content_margin_left = l
	sb.content_margin_top = t
	sb.content_margin_right = r
	sb.content_margin_bottom = b
	return sb


func frame_box(pad: int = 3) -> BevelBox:
	return box(SURFACE, BevelBox.Style3D.RAISED, pad, pad, pad, pad)


func title_box(active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = TITLE_A if active else TITLE_OFF
	sb.content_margin_left = 5
	sb.content_margin_top = 3
	sb.content_margin_right = 3
	sb.content_margin_bottom = 3
	return sb


func plain_box(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	return sb


func hline() -> Control:
	return EtchedRule.new(false)


func vline() -> Control:
	return EtchedRule.new(true)


func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func margins(node: Control, l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(node)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return m


func vbox(sep: int = 0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


func hbox(sep: int = 0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


func grow() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func section(text: String, color: Color = INK) -> Control:
	return label(text.to_upper(), tiny_b, 10, color, 1)


func group(title: String, content: Control, color: Color = INK) -> Control:
	var stack := vbox(0)
	var head := hbox(7)
	head.add_child(section(title, color))
	var rule := EtchedRule.new(false)
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(rule)
	stack.add_child(head)
	stack.add_child(spacer(8))
	stack.add_child(content)
	return stack
