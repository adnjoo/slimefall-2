extends Control

@onready var chat_log = $VBoxContainer/ChatLog
@onready var chat_input = $VBoxContainer/HBoxContainer/ChatInput
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton
@onready var host_button = $HBoxContainer/HostButton
@onready var join_button = $HBoxContainer/JoinButton
@onready var ip_input = $HBoxContainer/IPInput

const PORT = 9999
var is_host = false

func _ready():
	send_button.pressed.connect(_on_send_pressed)
	chat_input.text_submitted.connect(_on_text_submitted)
	host_button.pressed.connect(_host_game)
	join_button.pressed.connect(_join_game)

	var mp = get_tree().get_multiplayer()
	mp.peer_connected.connect(_on_peer_connected)
	mp.peer_disconnected.connect(_on_peer_disconnected)
	mp.connected_to_server.connect(_on_connected_to_server)
	mp.connection_failed.connect(_on_connection_failed)

func _on_send_pressed():
	_send_message(chat_input.text)

func _on_text_submitted(new_text):
	_send_message(new_text)

func _send_message(msg: String):
	if msg.strip_edges() == "":
		return

	# Show locally
	chat_log.push_color(Color.LIGHT_GREEN)
	chat_log.append_text("You: ")
	chat_log.pop()
	chat_log.append_text(msg + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count())
	chat_input.clear()

	# Send to others via RPC
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
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	get_tree().get_multiplayer().multiplayer_peer = peer
	is_host = true
	chat_log.append_text("Hosting on port %d...\n" % PORT)

func _join_game():
	var ip = ip_input.text.strip_edges()
	if ip == "":
		chat_log.append_text("Enter a valid IP!\n")
		return

	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	get_tree().get_multiplayer().multiplayer_peer = peer
	chat_log.append_text("Connecting to %s...\n" % ip)

func _on_peer_connected(id):
	chat_log.append_text("Peer %d connected.\n" % id)

func _on_peer_disconnected(id):
	chat_log.append_text("Peer %d disconnected.\n" % id)

func _on_connected_to_server():
	chat_log.append_text("Connected to server!\n")

func _on_connection_failed():
	chat_log.append_text("Connection failed.\n")
