extends Control

@onready var chat_log = $VBoxContainer/ChatLog
@onready var chat_input = $VBoxContainer/HBoxContainer/ChatInput
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton
@onready var host_button = $HBoxContainer/HostButton
@onready var join_button = $HBoxContainer/JoinButton
@onready var ip_input = $HBoxContainer/IPInput
@onready var mid = $Mid

var PlayerScene = preload("res://scenes/Player.tscn")
var self_player: Node = null
var is_host = false

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
	GDSync.client_joined.connect(_on_client_joined)

	GDSync.expose_func(self.receive_message)
	GDSync.expose_func(self.update_position)
	GDSync.expose_func(self.update_animation)

func _on_send_pressed():
	_send_message(chat_input.text)

func _on_text_submitted(new_text: String):
	_send_message(new_text)

func _process(delta):
	if self_player:
		GDSync.call_func(self.update_position, [GDSync.get_client_id(), self_player.global_position])

func update_position(client_id: int, pos: Vector2):
	var player_node := mid.get_node_or_null("Player_%d" % client_id)
	if player_node:
		player_node.global_position = pos

func update_animation(client_id: int, direction: float, anim_name: String):
	var player_node := mid.get_node_or_null("Player_%d" % client_id)
	if player_node:
		player_node.get_node("AnimatedSprite2D").scale.x = direction
		if not player_node.get_node("AnimatedSprite2D").is_playing() or player_node.get_node("AnimatedSprite2D").animation != anim_name:
			player_node.get_node("AnimatedSprite2D").play(anim_name)

func _spawn_player(client_id: int):
	var player = PlayerScene.instantiate()
	player.player_id = client_id
	player.name = "Player_%d" % client_id
	player.position = Vector2(100 + randi() % 300, 100)
	mid.add_child(player)

	GDSync.set_gdsync_owner(player, client_id)

	if client_id == GDSync.get_client_id():
		self_player = player

# --- Chat ---

func _send_message(msg: String):
	if msg.strip_edges() == "":
		return

	add_message("You", msg, Color.CYAN)
	chat_input.clear()
	GDSync.call_func(self.receive_message, [msg])

func receive_message(msg: String) -> void:
	var sender_id = GDSync.get_sender_id()
	var name = "Client %d" % sender_id if !GDSync.is_host() else "Host"
	add_message(name, msg, Color.YELLOW)

func add_message(name: String, msg: String, color: Color):
	chat_log.push_color(color)
	chat_log.append_text("%s: " % name)
	chat_log.pop()
	chat_log.append_text(msg + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count())

# --- Lobby/Connection ---

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
	add_message("System", "Client %d joined the lobby." % client_id, Color.LIGHT_BLUE)
	_spawn_player(client_id)
