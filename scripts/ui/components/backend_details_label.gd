extends Label


const PREFIX_TO_REPLACE: String = "koboldcpp/"
const UNAVAILABLE_TEXT: String = "Model name unavailable"
const AVAILABLE_TEXT: String = "Running on %s (%s %s)"

var _backend_info: Dictionary = {
	"name": "",
	"version": "",
}

@onready var get_backend_version_request: HTTPRequest = %GetBackendVersionRequest
@onready var get_ai_model_request: HTTPRequest = %GetAIModelRequest


func _ready() -> void:
	get_backend_version_request.request(Data.current_api_url + "extra/version", Constants.API_HEADERS, HTTPClient.METHOD_GET)


func _on_get_backend_version_request_completed(_result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != Constants.SUCCESS_RESPONSE_CODE:
		# NOTE: In Godot, HTTPRequests require an internet connection even if they're
		# connecting to localhost.
		text = "Backend connection timed out"
		Signals.add_message.emit(Constants.Participant.SYSTEM, "No internet connection! Some features may not work.")
		return
	
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == Error.OK:
		_backend_info.name = json.data.result
		_backend_info.version = json.data.version
		text = "Fetching AI model name..."
		get_ai_model_request.request(Data.current_api_url + "v1/model", Constants.API_HEADERS, HTTPClient.METHOD_GET)


func _on_get_ai_model_request_completed(_result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != Constants.SUCCESS_RESPONSE_CODE:
		text = UNAVAILABLE_TEXT
		return
	
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == Error.OK:
		text = AVAILABLE_TEXT % [(json.data.result as String).replace(PREFIX_TO_REPLACE, ""), _backend_info.name, _backend_info.version]
