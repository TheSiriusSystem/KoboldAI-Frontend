extends Node


signal user_name_changed()
signal ai_name_changed()

const CONFIG_FILE_PATH: String = "user://settings.cfg"

var api_url: String = Constants.API_DEFAULT_URL:
	set(value):
		api_url = value
		var config: ConfigFile = ConfigFile.new()
		config.set_value("api", "url", api_url)
		config.save(CONFIG_FILE_PATH)
var current_api_url: String = api_url
var system_prompt: String = "":
	set(value):
		system_prompt = value.lstrip(" ").rstrip(" ")
var user_name: String = Constants.USER_DEFAULT_NAME:
	set(value):
		value = value.lstrip(" ").rstrip(" ")
		if value != "" and value != ai_name:
			user_name = value
			user_name_changed.emit()
var ai_name: String = Constants.AI_DEFAULT_NAME:
	set(value):
		value = value.lstrip(" ").rstrip(" ")
		if value != "" and value != user_name:
			ai_name = value
			ai_name_changed.emit()
var ai_context_size: int = Constants.AI_DEFAULT_CONTEXT_SIZE:
	set(value):
		ai_context_size = clampi(value, 512, 4096)
var ai_max_output: int = Constants.AI_DEFAULT_MAX_OUTPUT:
	set(value):
		ai_max_output = clampi(value, 16, 512)
var ai_temperature: float = Constants.AI_DEFAULT_TEMPERATURE:
	set(value):
		ai_temperature = clampf(value, 0.1, 2.0)
var ai_repetition_penalty: float = Constants.AI_DEFAULT_REPETITION_PENALTY:
	set(value):
		ai_repetition_penalty = clampf(value, 1.0, 2.0)
var messages: Array = []:
	set(value):
		messages = value
		Signals.populate_message_list.emit()


func _ready() -> void:
	Signals.load_chat.connect(func(new_system_prompt: String, new_user_name: String, new_ai_name: String, new_ai_context_size: int, new_ai_max_output: int, new_ai_temperature: float, new_ai_repetition_penalty: float, new_messages: Array) -> void:
		system_prompt = new_system_prompt
		user_name = new_user_name
		ai_name = new_ai_name
		ai_context_size = new_ai_context_size
		ai_max_output = new_ai_max_output
		ai_temperature = new_ai_temperature
		ai_repetition_penalty = new_ai_repetition_penalty
		messages = new_messages
	)
	
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_FILE_PATH) == Error.OK:
		api_url = config.get_value("api", "url", Constants.API_DEFAULT_URL)
		current_api_url = api_url
