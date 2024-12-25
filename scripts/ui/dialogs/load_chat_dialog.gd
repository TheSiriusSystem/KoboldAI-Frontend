extends FileDialog


signal file_select_failed()

const DATA_SCHEMA: Dictionary = {
	"system_prompt": TYPE_STRING,
	"user_name": TYPE_STRING,
	"ai_name": TYPE_STRING,
	"ai_context_size": TYPE_FLOAT, #TYPE_INT
	"ai_max_output": TYPE_FLOAT, #TYPE_INT
	"ai_temperature": TYPE_FLOAT,
	"ai_repetition_penalty": TYPE_FLOAT,
	"messages": TYPE_ARRAY,
}


func _on_file_selected(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		var json: JSON = JSON.new()
		if json.parse(file.get_as_text()) == Error.OK:
			var valid_keys: int = 0
			for key: String in DATA_SCHEMA.keys():
				if json.data.has(key) and typeof(json.data[key]) == DATA_SCHEMA[key]:
					valid_keys += 1
			if valid_keys == DATA_SCHEMA.size():
				Signals.load_chat.emit(json.data.system_prompt, json.data.user_name, json.data.ai_name, json.data.ai_context_size, json.data.ai_max_output, json.data.ai_temperature, json.data.ai_repetition_penalty, json.data.messages)
			else:
				file_select_failed.emit()
		else:
			file_select_failed.emit()
		
		file.close()
