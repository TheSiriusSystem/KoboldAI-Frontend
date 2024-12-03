extends Label


const PLACEHOLDER_TEXT: String = "Input Tokens: %d"

@onready var tokenize_user_input_request: HTTPRequest = %TokenizeUserInput


func _on_message_edit_text_changed(new_text: String) -> void:
	tokenize_user_input_request.cancel_request()
	tokenize_user_input_request.request(Constants.API_URL + "extra/tokencount", Constants.API_HEADERS, HTTPClient.METHOD_POST, JSON.stringify({
		"prompt": new_text,
	}))


func _on_tokenize_user_input_request_completed(_result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != Constants.SUCCESS_RESPONSE_CODE:
		text = PLACEHOLDER_TEXT.replace("%d", "N/A")
		print("%s: Error" % tokenize_user_input_request.name)
		return
	
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == Error.OK:
		text = PLACEHOLDER_TEXT % [json.data.value - 1]
