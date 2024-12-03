extends Label


const PLACEHOLDER_TEXT: String = "Running on %s"

@onready var get_ai_model_request: HTTPRequest = %GetAIModel


func _ready() -> void:
	get_ai_model_request.request(Constants.API_URL + "v1/model", Constants.API_HEADERS, HTTPClient.METHOD_GET)


func _on_get_ai_model_request_completed(_result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != Constants.SUCCESS_RESPONSE_CODE:
		print("%s: Error" % get_ai_model_request.name)
		return
	
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == Error.OK:
		text = PLACEHOLDER_TEXT % (json.data.result as String).replace("koboldcpp/", "")
