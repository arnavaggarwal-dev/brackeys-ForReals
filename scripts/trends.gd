extends Node

const BASE := "https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article"
const PROJECT := "en.wikipedia/all-access/user"
const AGENT := "ForReals/1.0 (Brackeys Game Jam entry; godot-httprequest)"
const WINDOW_DAYS := 7
const REQUEST_TIMEOUT := 5.0
const DEADLINE := 8.0

const ARTICLES := {
	"sport": "Sport",
	"war": "War",
	"technology": "Technology",
	"politics": "Politics",
	"science": "Science",
	"food": "Food",
}

var weight: Dictionary = {}
var have_data := false
var status := "offline"

var _views: Dictionary = {}


func _ready() -> void:
	_fetch_all()


func topic_weight(topic: String) -> float:
	return float(weight.get(topic, 0.0))


func _fetch_all() -> void:
	status = "fetching"
	var topics: Array = ARTICLES.keys()
	for topic: String in topics:
		_send(topic, String(ARTICLES[topic]))

	var waited := 0.0
	while _views.size() < topics.size() and waited < DEADLINE:
		await get_tree().process_frame
		waited += get_process_delta_time()

	var most := 1.0
	for topic: String in topics:
		var v: int = int(_views.get(topic, -1))
		if v < 0:
			status = "offline"
			return
		most = maxf(most, float(v))

	for topic: String in topics:
		weight[topic] = float(_views[topic]) / most

	have_data = true
	status = "live"
	Game.roll_trends()
	Game.view_dirty.emit()


func _send(topic: String, article: String) -> void:
	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT
	add_child(http)
	http.request_completed.connect(
		func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
			_views[topic] = _parse(result, code, body)
			http.queue_free()
	)

	var now := Time.get_datetime_dict_from_system(true)
	var end_stamp := Time.get_unix_time_from_datetime_dict(now) - 86400
	var start_stamp := end_stamp - WINDOW_DAYS * 86400
	var url := "%s/%s/%s/daily/%s/%s" % [
		BASE, PROJECT, article.uri_encode(), _stamp(start_stamp), _stamp(end_stamp)
	]
	if http.request(url, ["User-Agent: " + AGENT, "Accept: application/json"]) != OK:
		_views[topic] = -1
		http.queue_free()


func _parse(result: int, code: int, body: PackedByteArray) -> int:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return -1
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("items"):
		return -1
	var total := 0
	for item: Dictionary in parsed["items"]:
		total += int(item.get("views", 0))
	return total


func _stamp(unix: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(unix)
	return "%04d%02d%02d" % [d["year"], d["month"], d["day"]]
