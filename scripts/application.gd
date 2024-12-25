extends CanvasLayer


signal ai_response_requested()

const AI_OTHER_STOP_SEQUENCES: PackedStringArray = [
	"Me",
	"You",
	"Human",
	"Boy",
	"Man",
	"Girl",
	"Woman",
]
const AI_GENKEY: String = "KCPP2342"
const MESSAGE_EDIT_PLACEHOLDER_TEXT: String = "Message %s"
const MESSAGE_BODY_SCENE: PackedScene = preload("res://scenes/ui/message_body.tscn")

var _is_busy: bool = false:
	set(value):
		_is_busy = value
		for message_body: MessageBody in message_body_container.get_children():
			message_body.delete_button_set_enabled(not _is_busy)
		message_edit.editable = not _is_busy
		send_message_button.disabled = _is_busy
		abort_response_button.disabled = not _is_busy
var _stop_sequences: PackedStringArray = []

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var message_body_container: VBoxContainer = %MessageBodyContainer
@onready var message_edit: LineEdit = %MessageEdit
@onready var send_message_button: Button = %SendMessageButton
@onready var abort_response_button: Button = %AbortResponseButton
@onready var generate_ai_response_request: HTTPRequest = %GenerateAIResponseRequest
@onready var abort_ai_response_request: HTTPRequest = %AbortAIResponseRequest


func _ready() -> void:
	Signals.add_message.connect(func(sender: Constants.Participant, content: String) -> void:
		Data.messages.push_back({
			"sender": sender,
			"timestamp": "%s %s" % [Time.get_time_string_from_system(), Time.get_date_string_from_system()],
			"content": content,
		})
		Signals.populate_message_list.emit()
		
		# Automatically scroll the container to the bottom.
		await scroll_container.get_v_scroll_bar().changed
		scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
	)
	
	Signals.populate_message_list.connect(func() -> void:
		for message_body: MessageBody in message_body_container.get_children():
			message_body.queue_free()
		
		for message: Dictionary in Data.messages:
			var message_body: MessageBody = MESSAGE_BODY_SCENE.instantiate()
			message_body_container.add_child(message_body)
			message_body.bind_to(message)
			message_body.deleted.connect(func() -> void:
				if not _is_busy:
					Data.messages.erase(message)
					Signals.populate_message_list.emit()
			)
	)
	
	Data.user_name_changed.connect(func() -> void:
		Signals.add_message.emit(Constants.Participant.SYSTEM, "Set your name to '%s'." % Data.user_name)
	)
	
	Data.ai_name_changed.connect(func() -> void:
		Signals.add_message.emit(Constants.Participant.SYSTEM, "Set the AI's name to '%s'." % Data.ai_name)
		message_edit.placeholder_text = MESSAGE_EDIT_PLACEHOLDER_TEXT % Data.ai_name
	)
	
	Signals.load_chat.emit(Constants.DEFAULT_SYSTEM_PROMPT, Constants.USER_DEFAULT_NAME, Constants.AI_DEFAULT_NAME, Constants.AI_DEFAULT_CONTEXT_SIZE, Constants.AI_DEFAULT_MAX_OUTPUT, Constants.AI_DEFAULT_TEMPERATURE, Constants.AI_DEFAULT_REPETITION_PENALTY, [])
	message_edit.placeholder_text = MESSAGE_EDIT_PLACEHOLDER_TEXT % Data.ai_name
	message_edit.text_changed.emit(message_edit.text)


func _is_message_edit_empty() -> bool:
	return message_edit.text.rstrip(" ") == ""


func _on_message_edit_text_submitted(new_text: String) -> void:
	if not _is_message_edit_empty():
		Signals.add_message.emit(Constants.Participant.USER, new_text)
		message_edit.text = ""
		message_edit.text_changed.emit(message_edit.text)
	_is_busy = true
	
	# Compile the conversation context.
	var prompt: String = ""
	if Data.system_prompt != "": # Combine the system prompt if it's set.
		prompt += "%s: %s - %s\n" % [Constants.SYSTEM_NAME, Data.ai_name, Data.system_prompt]
	for message: Dictionary in Data.messages: # Combine the message history.
		var get_message_sender_name: Callable = func() -> String:
			# NOTICE: As of Godot 4.3, match statements don't work properly here.
			if message.sender == Constants.Participant.USER:
				return Data.user_name
			elif message.sender == Constants.Participant.AI:
				return Data.ai_name
			return Constants.UNKNOWN_PARTICIPANT_NAME
		
		if message.sender != Constants.Participant.SYSTEM:
			prompt += "%s: %s\n" % [get_message_sender_name.call(), message.content]
	prompt += "%s:" % Data.ai_name # Let the AI know who to talk as.
	
	# Used to remove the need for chaining rstrip() later on.
	_stop_sequences = [
		"\n%s:" % Constants.SYSTEM_NAME,
		"\n%s:" % Data.user_name,
		"\n%s:" % Data.ai_name,
	]
	for other_stop_sequence: String in AI_OTHER_STOP_SEQUENCES:
		_stop_sequences.push_back("\n%s:" % other_stop_sequence.to_lower())
		_stop_sequences.push_back("\n%s:" % other_stop_sequence)
		_stop_sequences.push_back("\n%s:" % other_stop_sequence.to_upper())
	
	ai_response_requested.emit()
	generate_ai_response_request.request(Data.current_api_url + "v1/generate", Constants.API_HEADERS, HTTPClient.METHOD_POST, JSON.stringify({
		"max_context_length": Data.ai_context_size,
		"max_length": Data.ai_max_output,
		"prompt": prompt,
		"rep_pen": Data.ai_repetition_penalty,
		"temperature": Data.ai_temperature,
		"stop_sequence": _stop_sequences,
		"genkey": AI_GENKEY,
	}))


func _on_send_message_pressed() -> void:
	message_edit.text_submitted.emit(message_edit.text)


func _on_abort_response_pressed() -> void:
	if _is_busy:
		abort_ai_response_request.request(Data.current_api_url + "extra/abort", Constants.API_HEADERS, HTTPClient.METHOD_POST, JSON.stringify({
			"genkey": AI_GENKEY,
		}))


func _on_generate_ai_response_request_completed(_result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != Constants.SUCCESS_RESPONSE_CODE:
		return
	
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == Error.OK:
		for stop_sequence: String in _stop_sequences:
			json.data.results[0].text = json.data.results[0].text.rstrip(stop_sequence)
		
		Signals.add_message.emit(Constants.Participant.AI, json.data.results[0].text.lstrip(" ").lstrip("\n"))
		_is_busy = false
