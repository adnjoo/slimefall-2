extends Control

@onready var chat_log = $VBoxContainer/ChatLog
@onready var chat_input = $VBoxContainer/HBoxContainer/ChatInput
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton
@onready var host_button = $HBoxContainer/HostButton
@onready var join_button = $HBoxContainer/JoinButton
@onready var ip_input = $HBoxContainer/IPInput

var is_host = false

func _ready():
	send_button.pressed.connect(_on_send_pressed)
	chat_input.text_submitted.connect(_on_text_submitted)
	host_button.pressed.connect(_host_game)
	join_button.pressed.connect(_join_game)

	GDSync.connected.connect(_on_connected)
	GDSync.connection_failed.connect(_on_connection_failed)
	GDSync.disconnected.connect(_on_disconnected)

func _on_send_pressed():
	_send_message(chat_input.text)

func _on_text_submitted(new_text):
	_send_message(new_text)

func _send_message(msg: String):
	if msg.strip_edges() == "":
		return

	chat_log.push_color(Color.LIGHT_GREEN)
	chat_log.append_text("You: ")
	chat_log.pop()
	chat_log.append_text(msg + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count())
	chat_input.clear()

	rpc("receive_message", msg)

@rpc("any_peer")
func receive_message(msg: String):
	var peer_id = get_tree().get_multiplayer().get_remote_sender_id()
	var name = "Client %s" % peer_id if is_host and peer_id != 1 else "Host"

	chat_log.push_color(Color.SKY_BLUE)
	chat_log.append_text("%s: " % name)
	chat_log.pop()
	chat_log.append_text(msg + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count())

func _host_game():
	is_host = true
	GDSync.client.public_key = "2ff5cbd14c17ad78"  # Optional: set your own key
	GDSync.start_multiplayer()
	chat_log.append_text("Starting GD-Sync multiplayer host...\n")

func _join_game():
	GDSync.public_key = ip_input.text.strip_edges()
	if GDSync.public_key == "":
		chat_log.append_text("Enter a valid public key!\n")
		return

	GDSync.start_multiplayer()
	chat_log.append_text("Attempting to join via GD-Sync key...\n")

func _on_connected():
	chat_log.append_text("Connected via GD-Sync!\n")

func _on_connection_failed(error: int):
	match error:
		GDSync.ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			chat_log.append_text("Invalid GD-Sync public key.\n")
		GDSync.ENUMS.CONNECTION_FAILED.TIMEOUT:
			chat_log.append_text("Connection timed out.\n")
		_:
			chat_log.append_text("Unknown connection error: %d\n" % error)

func _on_disconnected():
	chat_log.append_text("Disconnected from GD-Sync session.\n")
