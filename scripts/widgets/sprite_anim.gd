class_name SpriteAnim
extends TextureRect

const SHEETS := {
	"heart": {
		"path": "res://assets/2d/heart.png",
		"cell": Vector2i(8, 8), "cols": 2, "frames": 3, "fps": 8.0,
	},
	"comment": {
		"path": "res://assets/2d/comments.png",
		"cell": Vector2i(8, 8), "cols": 2, "frames": 3, "fps": 8.0,
	},
	"follower": {
		"path": "res://assets/2d/followers.png",
		"cell": Vector2i(8, 8), "cols": 3, "frames": 9, "fps": 12.0,
	},
	"fire": {
		"path": "res://assets/2d/fire.png",
		"cell": Vector2i(32, 32), "cols": 5, "frames": 5, "fps": 8.0,
	},
	"money": {
		"path": "res://assets/2d/money.png",
		"cell": Vector2i(16, 16), "cols": 2, "frames": 4, "fps": 8.0,
	},
	"loading": {
		"path": "res://assets/2d/loading.png",
		"cell": Vector2i(120, 60), "cols": 5, "frames": 15, "fps": 30.0,
	},
}

const SCENE := "res://scenes/widgets/sprite_anim.tscn"

@export var sheet := "heart"
@export var px := 16.0
@export var looping := true
@export var fps := 0.0

var _atlas: AtlasTexture
var _cell := Vector2i(8, 8)
var _cols := 1
var _count := 1
var _rate := 12.0
var _frame := 0
var _clock := 0.0
var _playing := false


static func make(kind: String, size_px: float = 16.0, loops: bool = true) -> SpriteAnim:
	var node: SpriteAnim = load(SCENE).instantiate()
	node.sheet = kind
	node.px = size_px
	node.looping = loops
	return node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var spec: Dictionary = SHEETS.get(sheet, SHEETS["heart"])
	var cell: Vector2i = spec["cell"]
	custom_minimum_size = Vector2(px * float(cell.x) / float(cell.y), px)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_load_sheet()
	_show(0)
	_playing = looping
	set_process(true)


func _load_sheet() -> void:
	var spec: Dictionary = SHEETS.get(sheet, SHEETS["heart"])
	_cell = spec["cell"]
	_cols = int(spec["cols"])
	_count = int(spec["frames"])
	_rate = fps if fps > 0.0 else float(spec["fps"])

	_atlas = AtlasTexture.new()
	_atlas.atlas = load(String(spec["path"]))
	_atlas.region = Rect2(Vector2.ZERO, Vector2(_cell))
	texture = _atlas


func pop() -> void:
	_frame = 0
	_clock = 0.0
	_playing = true


func _show(n: int) -> void:
	if _atlas == null:
		return
	var col := n % _cols
	var row := n / _cols
	_atlas.region = Rect2(Vector2(col * _cell.x, row * _cell.y), Vector2(_cell))


func _process(delta: float) -> void:
	if not _playing or _count <= 1:
		return
	_clock += delta
	var step := 1.0 / maxf(1.0, _rate)
	while _clock >= step:
		_clock -= step
		_frame += 1
		if _frame >= _count:
			if looping:
				_frame = 0
			else:
				_frame = 0
				_playing = false
		_show(_frame)
