class_name Avatar
extends Control

const PERSONAS := [
	"res://assets/2d/persona.png",
	"res://assets/2d/persona1.png",
	"res://assets/2d/persona2.png",
	"res://assets/2d/persona3.png",
	"res://assets/2d/persona4.png",
	"res://assets/2d/persona5.png",
]

const SCENE := "res://scenes/widgets/avatar.tscn"

@export var persona := 0
@export var tint := Color("c0c0c0")

var _sprite: Texture2D


static func make(index: int, backdrop: Color, px: float = 32.0) -> Avatar:
	var node: Avatar = load(SCENE).instantiate()
	node.persona = posmod(index, PERSONAS.size())
	node.tint = backdrop
	node.custom_minimum_size = Vector2(px, px)
	return node


static func for_account(acc: Dictionary, px: float = 32.0) -> Avatar:
	var pick: int = absi(hash(String(acc["h"]))) % PERSONAS.size()
	return make(pick, Style.topic_color(String(acc["topic"])).lightened(0.72), px)


static func player(px: float = 32.0) -> Avatar:
	return make(int(Game.avatar.get("persona", 0)), Style.SURFACE_HI, px)


static func choice(option: Dictionary, px: float = 32.0) -> Avatar:
	return make(int(option.get("persona", 0)), Style.SURFACE_HI, px)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite = load(PERSONAS[posmod(persona, PERSONAS.size())])
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	if s < 6.0:
		return

	draw_rect(Rect2(Vector2.ZERO, Vector2(s - 1, 1)), Style.SHADOW)
	draw_rect(Rect2(Vector2.ZERO, Vector2(1, s - 1)), Style.SHADOW)
	draw_rect(Rect2(Vector2(0, s - 1), Vector2(s, 1)), Style.WHITE)
	draw_rect(Rect2(Vector2(s - 1, 0), Vector2(1, s)), Style.WHITE)
	draw_rect(Rect2(Vector2(1, 1), Vector2(s - 2, s - 2)), tint)

	if _sprite == null:
		return
	var scale := maxi(1, int((s - 2) / 8.0))
	var art := float(scale * 8)
	var at := (Vector2(s, s) - Vector2(art, art)) * 0.5
	draw_texture_rect(_sprite, Rect2(at.floor(), Vector2(art, art)), false)
