extends Label


enum GenerationStatus
{
	BLANK,
	TYPING,
	RESPONDED,
}

const TYPING_STATUS_TEXT: String = "%s is typing..."
const RESPONSE_TIME_TEXT: String = "%s responded in %.2f seconds"

var _generation_status: GenerationStatus = GenerationStatus.BLANK
var _generation_start_time: float = 0.0
var _generation_end_time: float = 0.0

@onready var generate_ai_response_request: HTTPRequest = %GenerateAIResponseRequest


func _ready() -> void:
	Data.ai_name_changed.connect(func() -> void:
		if _generation_status == GenerationStatus.RESPONDED:
			text = RESPONSE_TIME_TEXT % [Data.ai_name, _generation_end_time]
	)


func _get_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0


func _on_application_ai_response_requested() -> void:
	_generation_status = GenerationStatus.TYPING
	_generation_start_time = _get_seconds()
	text = TYPING_STATUS_TEXT % Data.ai_name


func _on_generate_ai_response_request_completed(_result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != Constants.SUCCESS_RESPONSE_CODE:
		_generation_status = GenerationStatus.BLANK
		text = ""
		return
	
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == Error.OK:
		_generation_status = GenerationStatus.RESPONDED
		_generation_end_time = _get_seconds() - _generation_start_time
		text = RESPONSE_TIME_TEXT % [Data.ai_name, _generation_end_time]
