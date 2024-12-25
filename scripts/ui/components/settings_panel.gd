extends Control


@onready var api_url_edit: LineEdit = $APIURLEdit
@onready var system_prompt_edit: TextEdit = $LeftSettings/SystemPrompt
@onready var user_name_edit: LineEdit = $LeftSettings/VBoxContainer/UserName/LineEdit
@onready var ai_name_edit: LineEdit = $LeftSettings/VBoxContainer/AIName/LineEdit
@onready var ai_context_size_box: SpinBox = $RightSettings/VBoxContainer2/AIContextSize/SpinBox
@onready var ai_max_output_box: SpinBox = $RightSettings/VBoxContainer2/AIMaxOutput/SpinBox
@onready var ai_temperature_box: SpinBox = $RightSettings/VBoxContainer/AITemperature/SpinBox
@onready var ai_repetition_penalty_box: SpinBox = $RightSettings/VBoxContainer/AIRepetitionPenalty/SpinBox
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	Signals.load_chat.connect(func(new_system_prompt: String, new_user_name: String, new_ai_name: String, new_ai_context_size: int, new_ai_max_output: int, new_ai_temperature: float, new_ai_repetition_penalty: float, _new_messages: Array) -> void:
		system_prompt_edit.text = new_system_prompt
		user_name_edit.text = new_user_name
		ai_name_edit.text = new_ai_name
		ai_context_size_box.value = new_ai_context_size
		ai_max_output_box.value = new_ai_max_output
		ai_temperature_box.value = new_ai_temperature
		ai_repetition_penalty_box.value = new_ai_repetition_penalty
	)
	
	api_url_edit.text = Data.api_url


func settings_set_enabled(enabled: bool) -> void:
	system_prompt_edit.editable = enabled
	user_name_edit.editable = enabled
	ai_name_edit.editable = enabled
	ai_context_size_box.editable = enabled
	ai_max_output_box.editable = enabled
	ai_temperature_box.editable = enabled
	ai_repetition_penalty_box.editable = enabled


func _on_user_name_text_submitted(new_text: String) -> void:
	Data.user_name = new_text


func _on_ai_name_text_submitted(new_text: String) -> void:
	Data.ai_name = new_text


func _on_system_prompt_text_changed() -> void:
	Data.system_prompt = system_prompt_edit.text


func _on_ai_context_size_value_changed(value: float) -> void:
	Data.ai_context_size = int(value)


func _on_ai_max_output_value_changed(value: float) -> void:
	Data.ai_max_output = int(value)


func _on_ai_temperature_value_changed(value: float) -> void:
	Data.ai_temperature = value


func _on_ai_repetition_penalty_value_changed(value: float) -> void:
	Data.ai_repetition_penalty = value


func _on_generate_ai_response_request_completed(_result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != Constants.SUCCESS_RESPONSE_CODE:
		return
	
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) == Error.OK:
		settings_set_enabled(true)


func _on_api_url_edit_text_submitted(new_text: String) -> void:
	if (new_text.begins_with("http://") or new_text.begins_with("https://")) and new_text.ends_with("/api/"):
		Data.api_url = new_text
		audio_stream_player.play()
