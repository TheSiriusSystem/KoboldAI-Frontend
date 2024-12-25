extends FileDialog


func appear() -> void:
	current_file = "chat_%s_%s.json" % [Time.get_date_string_from_system(), Time.get_time_string_from_system().replace(":", "")]
	popup_centered_ratio(0.5)


func _on_file_selected(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"system_prompt": Data.system_prompt,
			"user_name": Data.user_name,
			"ai_name": Data.ai_name,
			"ai_context_size": Data.ai_context_size,
			"ai_max_output": Data.ai_max_output,
			"ai_temperature": Data.ai_temperature,
			"ai_repetition_penalty": Data.ai_repetition_penalty,
			"messages": Data.messages,
		}, "\t"))
		file.close()
