extends ConfirmationDialog


func _on_confirmed() -> void:
	Signals.load_chat.emit(Constants.DEFAULT_SYSTEM_PROMPT, Constants.USER_DEFAULT_NAME, Constants.AI_DEFAULT_NAME, Constants.AI_DEFAULT_CONTEXT_SIZE, Constants.AI_DEFAULT_MAX_OUTPUT, Constants.AI_DEFAULT_TEMPERATURE, Constants.AI_DEFAULT_REPETITION_PENALTY, [])
