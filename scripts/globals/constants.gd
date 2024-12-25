class_name Constants
extends Object
## Stores globally-accessible enums and constants.


enum Participant
{
	SYSTEM,
	USER,
	AI,
}

const KEYS_AND_TYPES: Dictionary = {
	"system_prompt": TYPE_STRING,
	"user_name": TYPE_STRING,
	"ai_name": TYPE_STRING,
	"ai_context_size": TYPE_FLOAT, #TYPE_INT
	"ai_max_output": TYPE_FLOAT, #TYPE_INT
	"ai_temperature": TYPE_FLOAT,
	"ai_repetition_penalty": TYPE_FLOAT,
	"messages": TYPE_ARRAY,
}
const API_DEFAULT_URL: String = "http://localhost:5001/api/"
const API_HEADERS: PackedStringArray = [
	"Content-Type: application/json",
]
const SUCCESS_RESPONSE_CODE: int = 200
const DEFAULT_SYSTEM_PROMPT: String = ""
const UNKNOWN_PARTICIPANT_NAME: String = "???"
const SYSTEM_NAME: String = "System"
const USER_DEFAULT_NAME: String = "User"
const AI_DEFAULT_NAME: String = "AI"
const AI_DEFAULT_CONTEXT_SIZE: int = 2048
const AI_DEFAULT_MAX_OUTPUT: int = 256
const AI_DEFAULT_TEMPERATURE: float = 0.7
const AI_DEFAULT_REPETITION_PENALTY: float = 1.07
