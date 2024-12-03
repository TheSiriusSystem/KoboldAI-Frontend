extends CanvasLayer


const AI_NAME: String = "Alex"
const AI_CONTEXT_SIZE: int = 8192
const AI_MAX_OUTPUT: int = 320
const AI_GENKEY: String = "KCPP2342"
const TYPING_STATUS_TEXT: String = "%s is typing..."
const RESPONSE_TIME_TEXT: String = "%s responded in %.2f seconds"

@export var message_body_scene: PackedScene

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var message_body_container: VBoxContainer = %MessageBodyContainer
@onready var status_label: Label = %StatusLabel
@onready var message_edit: LineEdit = %MessageEdit
@onready var send_message_button: Button = %SendMessageButton
@onready var retry_response_button: Button = %RetryResponseButton
@onready var abort_generation_button: Button = %AbortGenerationButton
@onready var generate_ai_response_request: HTTPRequest = %GenerateAIResponse
@onready var abort_ai_response_request: HTTPRequest = %AbortAIResponse

var _user_name: String = "User"
var _messages: Array = []
var _is_busy: bool = false:
	set(value):
		_is_busy = value
		message_edit.editable = not _is_busy
		send_message_button.disabled = _is_busy if not _is_message_edit_empty() else true
		retry_response_button.disabled = _is_busy if _is_last_message_from_ai() else true
		abort_generation_button.disabled = not _is_busy
		for message_body: VBoxContainer in message_body_container.get_children():
			(message_body.get_node(^"%DeleteButton") as Button).disabled = _is_busy
var _generation_start_time: float = 0.0


func _ready() -> void:
	if OS.has_environment("USERNAME"): # Windows
		_user_name = OS.get_environment("USERNAME")
	elif OS.has_environment("USER"): # macOS, Linux
		_user_name = OS.get_environment("USER")
	_user_name = "Blake"
	
	_on_message_edit_text_changed(message_edit.text)
	message_edit.placeholder_text %= AI_NAME


func _send_request_to_ai() -> void:
	_is_busy = true
	
	var prompt: String = ""
	
	# Compile the conversation context.
	for message: Dictionary in _messages:
		prompt += "%s: %s\n" % [message.sender, message.content]
	prompt += "%s:" % AI_NAME # So the AI knows who to talk as.
	
	_generation_start_time = get_seconds()
	status_label.text = TYPING_STATUS_TEXT % AI_NAME
	generate_ai_response_request.request(Constants.API_URL + "v1/generate", Constants.API_HEADERS, HTTPClient.METHOD_POST, JSON.stringify({
		"max_context_length": AI_CONTEXT_SIZE,
		"max_length": AI_MAX_OUTPUT,
		"prompt": prompt,
		"stop_sequence": ["\n%s:" % _user_name, "\n%s:" % AI_NAME],
		"genkey": AI_GENKEY,
	}))


func _add_message(sender: String, content: String) -> void:
	_messages.push_back({
		"sender": sender,
		"content": content,
		"timestamp": Time.get_time_string_from_system(),
	})
	_populate_message_list()
	await scroll_container.get_v_scroll_bar().changed
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value


func _remove_message(message_index: int) -> void:
	if not _is_busy:
		_messages.remove_at(message_index)
		_populate_message_list()
		retry_response_button.disabled = _messages.size() == 1 or not _is_last_message_from_ai()


func _populate_message_list() -> void:
	# Clear existing messages in the container.
	for message_body: VBoxContainer in message_body_container.get_children():
		message_body.queue_free()
	
	for message_index: int in range(_messages.size()):
		var message: Dictionary = _messages[message_index]
		
		var message_body: VBoxContainer = message_body_scene.instantiate()
		message_body.name = "MessageBody%d" % message_index
		(message_body.get_node(^"%Username") as Label).text = message.sender
		(message_body.get_node(^"%Content") as Label).text = message.content
		(message_body.get_node(^"%Timestamp") as Label).text = message.timestamp
		(message_body.get_node(^"%DeleteButton") as Button).pressed.connect(func() -> void:
			_remove_message(message_index)
		)
		message_body_container.add_child(message_body)


func get_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0


func _is_message_edit_empty() -> bool:
	return message_edit.text.rstrip(" ") == ""


func _is_last_message_from_ai() -> bool:
	return _messages.size() > 0 and _messages[_messages.size() - 1].sender == AI_NAME


func _on_message_edit_text_changed(_new_text: String) -> void:
	send_message_button.disabled = _is_message_edit_empty()


func _on_message_edit_text_submitted(new_text: String) -> void:
	if not _is_message_edit_empty():
		message_edit.text = ""
		_on_message_edit_text_changed(message_edit.text)
		_add_message(_user_name, new_text)
		_send_request_to_ai()


func _on_send_message_pressed() -> void:
	_on_message_edit_text_submitted(message_edit.text)


func _on_retry_response_pressed() -> void:
	if _is_last_message_from_ai():
		_remove_message(_messages.size() - 1)
		_send_request_to_ai()


func _on_abort_generation_pressed() -> void:
	if _is_busy:
		abort_ai_response_request.request(Constants.API_URL + "extra/abort", Constants.API_HEADERS, HTTPClient.METHOD_POST, JSON.stringify({
			"genkey": AI_GENKEY,
		}))


func _on_generate_ai_response_request_completed(_result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != Constants.SUCCESS_RESPONSE_CODE:
		print("%s: Error" % generate_ai_response_request.name)
		return
	
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == Error.OK:
		status_label.text = RESPONSE_TIME_TEXT % [AI_NAME, get_seconds() - _generation_start_time]
		_add_message(AI_NAME, json.data.results[0].text.lstrip(" ").rstrip("\n%s:" % _user_name).rstrip("\n%s:" % AI_NAME))
		_is_busy = false
