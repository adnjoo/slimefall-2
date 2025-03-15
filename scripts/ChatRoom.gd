extends Control

@onready var chat_log = $VBoxContainer/ChatLog
@onready var chat_input = $VBoxContainer/HBoxContainer/ChatInput
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton
@onready var host_button = $HBoxContainer/HostButton
@onready var join_button = $HBoxContainer/JoinButton
@onready var ip_input = $HBoxContainer/IPInput  # Used as lobby name input

var is_host = true

func _ready():
	send_button.pressed.connect(_on_send_pressed)
	chat_input.text_submitted.connect(_on_text_submitted)
	host_button.pressed.connect(_host_game)
	join_button.pressed.connect(_join_game)

	GDSync.connected.connect(_on_connected)
	GDSync.connection_failed.connect(_on_connection_failed)
	GDSync.disconnected.connect(_on_disconnected)
	GDSync.lobby_created.connect(_on_lobby_created)
	GDSync.lobby_creation_failed.connect(_on_lobby_creation_failed)
	GDSync.lobby_joined.connect(_on_lobby_joined)
	GDSync.lobby_join_failed.connect(_on_lobby_join_failed)

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
	var name = "Client %s" % peer_id if !GDSync.is_host() else "Host"

	chat_log.push_color(Color.SKY_BLUE)
	chat_log.append_text("%s: " % name)
	chat_log.pop()
	chat_log.append_text(msg + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count())

func _host_game():
	is_host = true
	var lobby_name = ip_input.text.strip_edges()
	if lobby_name == "":
		chat_log.append_text("Enter a lobby name to host.\n")
		return

	# Step 1: Start the GD-Sync multiplayer system
	GDSync.connected.connect(func ():
		GDSync.create_lobby(lobby_name, "", true, 10, {})
		chat_log.append_text("Creating lobby: %s...\n" % lobby_name)
	)

	GDSync.connection_failed.connect(_on_connection_failed)

	GDSync.start_multiplayer()


func _join_game():
	is_host = false
	var lobby_name = ip_input.text.strip_edges()
	if lobby_name == "":
		chat_log.append_text("Enter a lobby name to join.\n")
		return

	GDSync.connected.connect(func ():
		GDSync.join_lobby(lobby_name, "")
		chat_log.append_text("Joining lobby: %s...\n" % lobby_name)
	)

	GDSync.connection_failed.connect(_on_connection_failed)

	GDSync.start_multiplayer()


func _on_lobby_created(lobby_name: String):
	chat_log.append_text("Lobby '%s' created successfully.\n" % lobby_name)
	GDSync.start_multiplayer()

func _on_lobby_creation_failed(lobby_name: String, error: int):
	chat_log.append_text("Failed to create lobby '%s'. Error code: %d\n" % [lobby_name, error])

func _on_lobby_joined(lobby_name: String):
	chat_log.append_text("Joined lobby '%s' successfully.\n" % lobby_name)
	GDSync.start_multiplayer()

func _on_lobby_join_failed(lobby_name: String, error: int):
	chat_log.append_text("Failed to join lobby '%s'. Error code: %d\n" % [lobby_name, error])

func _on_connected():
	chat_log.append_text("Connected via GD-Sync.\n")

func _on_connection_failed(error: int):
	match error:
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			chat_log.append_text("Invalid API key (plugin config).\n")
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			chat_log.append_text("Connection timed out.\n")
		_:
			chat_log.append_text("Unknown connection error: %d\n" % error)

func _on_disconnected():
	chat_log.append_text("Disconnected from GD-Sync session.\n")
