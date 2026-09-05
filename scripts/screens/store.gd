class_name Store
extends RefCounted

const ABILITY_TEXT := {
	"no_throttle": "ignores the reach limit no matter how suspicious you are",
	"launder": "counts as checkable for suspicion, uncheckable for reach",
	"triangulate": "all three of your hashtags count as trending",
	"scrubbed": "costs no suspicion at all, but travels 40% less far",
	"inoculate": "takes 25 off your suspicion instead of adding any",
	"chain": "the post keeps earning for twice as long",
	"recursive": "reach grows 4% for every post you have already made",
}

static var _open := false


static func open() -> void:
	if not Game.store_open():
		Game.toast_requested.emit(
			"The store is not open to you",
			"reach %d followers first" % Data.STORE_UNLOCK, true
		)
		return
	_open = true
	_render()


static func close() -> void:
	_open = false
	Dialog.close()


static func refresh() -> void:
	if _open:
		_render()


static func _render() -> void:
	var body := Dialog.open("Speech Fragment Store", 760.0, close)

	body.add_child(Dialog.message(
		Icon.Kind.FOLDER,
		"Things you cannot say for free. Everything here goes into the deck you are "
		+ "dealt from each morning."
	))
	body.add_child(Style.spacer(12))
	body.add_child(_balance())
	body.add_child(Style.spacer(14))

	var plain: Array = []
	var special: Array = []
	for f: Dictionary in Data.all_stock():
		if Data.ability_of(f) == "":
			plain.append(f)
		else:
			special.append(f)

	body.add_child(Style.group("Does something nobody else can", _shelf(special)))
	body.add_child(Style.spacer(16))
	body.add_child(Style.group("Plain stock", _shelf(plain)))

	var row := Dialog.buttons()
	var done := Dialog.button("Close")
	done.pressed.connect(close)
	row.add_child(done)
	Dialog.actions(row)


static func _balance() -> Control:
	var well := Dialog.well(10)
	var col := Style.vbox(4)
	var row := Style.hbox(10)
	row.add_child(SpriteAnim.make("money", 16.0))
	row.add_child(Style.label("Creator payout", Style.ui_r, 14, Style.INK_SOFT))
	row.add_child(Style.grow())
	row.add_child(Style.live_num(
		func() -> String: return "£%s" % Game.commas(int(Game.payout)), 15, Style.OK_GREEN
	))
	col.add_child(row)
	col.add_child(Style.body(
		"The platform pays you £%d for every 1,000 people a post reaches. It arrives "
			% int(Data.PAYOUT_PER_1K)
		+ "slowly, while the post is still travelling.",
		Style.ui_r, 12, Style.INK_SOFT, 3
	))
	well.add_child(col)
	return well


static func _shelf(stock: Array) -> Control:
	var list := PanelContainer.new()
	list.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 2, 2, 2, 2)
	)
	var col := Style.vbox(0)
	for f: Dictionary in stock:
		col.add_child(_row(f))
	list.add_child(col)
	return list


static func _row(f: Dictionary) -> Control:
	var bought := Game.owns(f)
	var affordable := Game.can_afford(f)
	var ability := Data.ability_of(f)

	var t := Tappable.new(Vector4(9, 7, 9, 8), Tappable.Look.LIST)
	t.set_enabled(not bought and affordable)

	var row := Style.hbox(10)
	var col := Style.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var head := Style.hbox(8)
	head.add_child(Style.label(
		String(f["text"]), Style.ui_b, 15,
		Style.INK_FAINT if bought else (Style.ALARM if ability != "" else Style.INK)
	))
	head.add_child(Style.label(String(f["tag"]), Style.ui_r, 12, Style.INK_FAINT))
	col.add_child(head)

	if ability != "":
		col.add_child(Style.body(
			String(ABILITY_TEXT.get(ability, "")), Style.ui_r, 12, Style.INK_SOFT, 3
		))
	else:
		col.add_child(Style.body(_plain_note(f), Style.ui_r, 12, Style.INK_SOFT, 3))
	row.add_child(col)

	var right := Style.vbox(2)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if bought:
		right.add_child(Style.num("owned", 10, Style.OK_GREEN))
	else:
		right.add_child(Style.num(
			"£%d" % Data.price_of(f), 13,
			Style.INK if affordable else Style.INK_FAINT
		))
		if not affordable:
			right.add_child(Style.num("cannot afford", 9, Style.INK_FAINT))
	row.add_child(right)

	t.add_content(row)
	if not bought and affordable:
		t.pressed.connect(func() -> void:
			Game.buy(f)
			refresh())
	return t


static func _plain_note(f: Dictionary) -> String:
	var bits: Array[String] = []
	if f.has("base"):
		bits.append("reach %d" % int(f["base"]))
	else:
		bits.append("x%.1f reach" % float(f["reach"]))
	if float(f.get("susp", 0.0)) > 0.0:
		bits.append("+%d suspicion" % int(f["susp"]))
	return " · ".join(bits)
