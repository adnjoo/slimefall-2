extends Control

@onready var chat_log = $VBoxContainer/ChatLog
@onready var chat_input = $VBoxContainer/HBoxContainer/ChatInput
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton

func _ready():
	send_button.pressed.connect(_on_send_pressed)
	chat_input.text_submitted.connect(_on_text_submitted)

func _on_send_pressed():
	_send_message(chat_input.text)

func _on_text_submitted(new_text):
	_send_message(new_text)

func _send_message(msg: String):
	if msg.strip_edges() == "":
		return

	# Push color manually (Godot 4 style)
	chat_log.push_color(Color.LIGHT_BLUE)
	chat_log.append_text("Player: ")
	chat_log.pop()

	chat_log.append_text(msg + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count())
	chat_input.clear()
