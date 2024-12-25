extends Node
## Stores globally-accessible signals.


#region Methods
@warning_ignore("unused_signal") signal add_message(sender: Constants.Participant, content: String)
@warning_ignore("unused_signal") signal populate_message_list()
@warning_ignore("unused_signal") signal load_chat(new_system_prompt: String, new_user_name: String, new_ai_name: String, new_ai_context_size: int, new_ai_max_output: int, new_messages: Array)
#endregion
