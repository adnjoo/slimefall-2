extends Control

@onready var chat_log = $VBoxContainer/ChatLog
@onready var chat_input = $VBoxContainer/HBoxContainer/ChatInput
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton
@onready var host_button = $HBoxContainer/HostButton
@onready var join_button = $HBoxContainer/JoinButton
@onready var ip_input = $HBoxContainer/IPInput  # Used as lobby name input

@onready var PlayerScene = preload("res://scenes/Player.tscn")
@onready var mid = $Mid

var is_host = false

func _ready():
	send_button.pressed.connect(_on_send_pressed)
	chat_input.text_submitted.connect(_on_text_submitted)
	host_button.pressed.connect(_host_game)
	join_button.pressed.connect(_join_game)

	# GD-Sync signals
	GDSync.connected.connect(_on_connected)
	GDSync.connection_failed.connect(_on_connection_failed)
	GDSync.disconnected.connect(_on_disconnected)
	GDSync.lobby_created.connect(_on_lobby_created)
	GDSync.lobby_creation_failed.connect(_on_lobby_creation_failed)
	GDSync.lobby_joined.connect(_on_lobby_joined)
	GDSync.lobby_join_failed.connect(_on_lobby_join_failed)
	GDSync.client_joined.connect(_on_client_joined)

	# Expose chat function
	GDSync.expose_func(receive_message)

func _on_send_pressed():
	_send_message(chat_input.text)

func _on_text_submitted(new_text):
	_send_message(new_text)

func _send_message(msg: String):
	if msg.strip_edges() == "":
		return

	add_message("You", msg, Color.CYAN)
	chat_input.clear()

	# Send to others using GD-Sync remote call
	GDSync.call_func(receive_message, [msg])

func receive_message(msg: String) -> void:
	var sender_id = GDSync.get_sender_id()
	var name = "Client %s" % sender_id if !GDSync.is_host() else "Host"
	add_message(name, msg, Color.YELLOW)

func add_message(name: String, msg: String, color: Color):
	chat_log.push_color(color)
	chat_log.append_text("%s: " % name)
	chat_log.pop()
	chat_log.append_text(msg + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count())

func _host_game():
	is_host = true
	var lobby_name = ip_input.text.strip_edges()
	if lobby_name == "":
		add_message("System", "Enter a lobby name to host.", Color.RED)
		return

	GDSync.connected.connect(func ():
		GDSync.create_lobby(lobby_name, "", true, 10, {})
		await get_tree().create_timer(0.1).timeout
		GDSync.join_lobby(lobby_name, "")
	)

	GDSync.start_multiplayer()

func _join_game():
	is_host = false
	var lobby_name = ip_input.text.strip_edges()
	if lobby_name == "":
		add_message("System", "Enter a lobby name to join.", Color.RED)
		return

	GDSync.connected.connect(func ():
		GDSync.join_lobby(lobby_name, "")
	)

	GDSync.start_multiplayer()

func _on_connected():
	add_message("System", "Connected via GD-Sync.", Color.GRAY)

func _on_disconnected():
	add_message("System", "Disconnected from GD-Sync.", Color.GRAY)

func _on_lobby_created(lobby_name: String):
	add_message("System", "Lobby '%s' created successfully." % lobby_name, Color.GREEN)

func _on_lobby_creation_failed(lobby_name: String, error: int):
	add_message("System", "Failed to create lobby '%s'. Error: %d" % [lobby_name, error], Color.RED)

func _on_lobby_joined(lobby_name: String):
	add_message("System", "Joined lobby '%s' successfully." % lobby_name, Color.GREEN)

	var player = PlayerScene.instantiate()
	player.position = Vector2(100, 100)  # Adjust spawn position as needed
	mid.add_child(player)

func _on_lobby_join_failed(lobby_name: String, error: int):
	add_message("System", "Failed to join lobby '%s'. Error: %d" % [lobby_name, error], Color.RED)

func _on_connection_failed(error: int):
	match error:
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			add_message("System", "Invalid API key.", Color.RED)
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			add_message("System", "Connection timed out.", Color.RED)
		_:
			add_message("System", "Unknown connection error: %d" % error, Color.RED)

func _on_client_joined(client_id: int):
	print("Client %d joined the lobby." % client_id)
	add_message("System", "Client %d joined the lobby." % client_id, Color.LIGHT_BLUE)
