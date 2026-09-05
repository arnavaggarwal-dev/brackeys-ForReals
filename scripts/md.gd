class_name Md
extends RefCounted

const H_SIZES := [20, 17, 15, 14, 13, 13]
const NUM_FONT := "res://assets/fonts/Silkscreen-Bold.ttf"


static func render(text: String, width_hint: float = 0.0) -> Control:
	var col := Style.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if width_hint > 0.0:
		col.custom_minimum_size.x = width_hint

	var lines := text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
	var i := 0
	var first := true
	while i < lines.size():
		var line := String(lines[i])
		var trimmed := line.strip_edges()

		if trimmed == "":
			i += 1
			continue

		if not first:
			col.add_child(Style.spacer(8))
		first = false

		if trimmed.begins_with("```"):
			var code: Array[String] = []
			i += 1
			while i < lines.size() and not String(lines[i]).strip_edges().begins_with("```"):
				code.append(String(lines[i]))
				i += 1
			i += 1
			col.add_child(_code_block("\n".join(code)))
			continue

		if _is_rule(trimmed):
			col.add_child(Style.hline())
			i += 1
			continue

		if trimmed.begins_with("#"):
			var level := 0
			while level < trimmed.length() and trimmed[level] == "#":
				level += 1
			col.add_child(_heading(trimmed.substr(level).strip_edges(), level))
			i += 1
			continue

		if trimmed.begins_with(">"):
			var quote: Array[String] = []
			while i < lines.size() and String(lines[i]).strip_edges().begins_with(">"):
				quote.append(String(lines[i]).strip_edges().substr(1).strip_edges())
				i += 1
			col.add_child(_quote(" ".join(quote)))
			continue

		if _bullet_of(trimmed) != "" or _ordered_of(trimmed) != "":
			var items: Array[String] = []
			var marks: Array[String] = []
			while i < lines.size():
				var t := String(lines[i]).strip_edges()
				var b := _bullet_of(t)
				var o := _ordered_of(t)
				if b != "":
					marks.append("•")
					items.append(b)
				elif o != "":
					marks.append("%d." % (marks.size() + 1))
					items.append(o)
				else:
					break
				i += 1
				while i < lines.size():
					var cont := String(lines[i])
					var flat := cont.strip_edges()
					if flat == "" or cont == flat:
						break
					if _bullet_of(flat) != "" or _ordered_of(flat) != "":
						break
					items[-1] = items[-1] + " " + flat
					i += 1
			col.add_child(_list(marks, items))
			continue

		var para: Array[String] = []
		while i < lines.size():
			var t := String(lines[i]).strip_edges()
			if t == "" or _is_rule(t) or t.begins_with("#") or t.begins_with(">") \
					or t.begins_with("```") or _bullet_of(t) != "" or _ordered_of(t) != "":
				break
			para.append(t)
			i += 1
		col.add_child(_paragraph(" ".join(para)))

	return col


static func _is_rule(t: String) -> bool:
	return t == "---" or t == "***" or t == "___"


static func _bullet_of(t: String) -> String:
	for mark: String in ["- ", "* ", "+ "]:
		if t.begins_with(mark):
			return t.substr(2).strip_edges()
	return ""


static func _ordered_of(t: String) -> String:
	var dot := t.find(". ")
	if dot <= 0 or dot > 3:
		return ""
	if not t.substr(0, dot).is_valid_int():
		return ""
	return t.substr(dot + 2).strip_edges()


static func _heading(text: String, level: int) -> Control:
	var size: int = H_SIZES[clampi(level - 1, 0, H_SIZES.size() - 1)]
	var col := Style.vbox(4)
	col.add_child(_rich("[b]%s[/b]" % inline(text), size, Style.INK))
	if level <= 2:
		col.add_child(Style.hline())
	return col


static func _paragraph(text: String) -> Control:
	return _rich(inline(text), 13, Style.INK_SOFT)


static func _quote(text: String) -> Control:
	var row := Style.hbox(9)
	var bar := ColorRect.new()
	bar.color = Style.HOT
	bar.custom_minimum_size.x = 3
	bar.size_flags_vertical = Control.SIZE_FILL
	row.add_child(bar)
	row.add_child(_rich(inline(text), 13, Style.INK))
	return row


static func _list(marks: Array[String], items: Array[String]) -> Control:
	var col := Style.vbox(5)
	for n in items.size():
		var row := Style.hbox(8)
		var mark := Style.label(marks[n], Style.ui_b, 13, Style.HOT)
		mark.custom_minimum_size.x = 18
		mark.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		row.add_child(mark)
		row.add_child(_rich(inline(items[n]), 13, Style.INK_SOFT))
		col.add_child(row)
	return col


static func _code_block(code: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", Style.box(Style.FIELD, BevelBox.Style3D.SUNKEN, 9, 8, 9, 9)
	)
	var body := Style.body(code, Style.tiny_r, 11, Style.INK, 4)
	panel.add_child(body)
	return panel


static func _rich(bb: String, size: int, color: Color) -> RichTextLabel:
	var r := Style.rich(bb, Style.ui_r, size, color, 4.0)
	r.add_theme_font_override("italics_font", Style.ui_m)
	r.add_theme_font_override("mono_font", Style.tiny_r)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_font_size_override("mono_font_size", size - 2)
	return r


static func inline(text: String) -> String:
	var out := _sub(text, "\\[([^\\]]*)\\]\\(([^)]*)\\)", "$1")
	out = out.replace("[", "[lb]")
	out = _sub(out, "`([^`]+)`", "[code]$1[/code]")
	out = _sub(out, "\\*\\*([^*]+)\\*\\*", "[b]$1[/b]")
	out = _sub(out, "__([^_]+)__", "[b]$1[/b]")
	out = _sub(out, "\\*([^*]+)\\*", "[i]$1[/i]")
	out = _sub(out, "(?<![A-Za-z0-9])_([^_]+)_(?![A-Za-z0-9])", "[i]$1[/i]")
	return _sub(out, "([0-9]+)", "[font=%s]$1[/font]" % NUM_FONT)


static func _sub(text: String, pattern: String, replace: String) -> String:
	var re := RegEx.new()
	if re.compile(pattern) != OK:
		return text
	return re.sub(text, replace, true)
