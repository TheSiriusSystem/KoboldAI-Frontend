class_name MessageBody
extends VBoxContainer


signal deleted()

const AVATAR_UNKNOWN: Texture2D = preload("res://sprites/avatar_unknown.png")
const AVATAR_SYSTEM: Texture2D = preload("res://sprites/avatar_system.png")
const AVATAR_USER: Texture2D = preload("res://sprites/avatar_user.png")
const AVATAR_AI: Texture2D = preload("res://sprites/avatar_ai.png")

var _is_bound: bool = false

@onready var avatar_rect: TextureRect = %Avatar
@onready var username_label: Label = %Username
@onready var timestamp_label: Label = %Timestamp
@onready var delete_button: Button = %DeleteButton
@onready var content_label: Label = %Content


func bind_to(message: Dictionary) -> void:
	if _is_bound:
		push_error("Message body is already bound.")
		return
	
	_is_bound = true
	
	# NOTICE: As of Godot 4.3, match statements don't work properly here.
	if message.sender == Constants.Participant.SYSTEM:
		_set_avatar_and_username(AVATAR_SYSTEM, Constants.SYSTEM_NAME)
	elif message.sender == Constants.Participant.USER:
		_set_avatar_and_username(AVATAR_USER, Data.user_name)
	elif message.sender == Constants.Participant.AI:
		_set_avatar_and_username(AVATAR_AI, Data.ai_name)
	else:
		_set_avatar_and_username(AVATAR_UNKNOWN, Constants.UNKNOWN_PARTICIPANT_NAME)
	timestamp_label.text = message.timestamp
	delete_button.pressed.connect(deleted.emit)
	content_label.text = message.content


func delete_button_set_enabled(enabled: bool) -> void:
	delete_button.disabled = not enabled


func _set_avatar_and_username(avatar: Texture2D, username: String) -> void:
	avatar_rect.texture = avatar
	username_label.text = username
