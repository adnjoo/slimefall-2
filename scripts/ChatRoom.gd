extends Control

@onready var chat_log = $VBoxContainer/ChatLog
@onready var chat_input = $VBoxContainer/HBoxContainer/ChatInput
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton
@onready var host_button = $HBoxContainer/HostButton
@onready var join_button = $HBoxContainer/JoinButton
@onready var ip_input = $HBoxContainer/IPInput

var signaling := WebSocketPeer.new()
var webrtc := WebRTCMultiplayerPeer.new()
var rtc_config := {
	"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
}
var peer_map := {}

const SIGNALING_URL = "ws://localhost:8080"
#const SIGNALING_URL = "wss://demos.kaazing.com/echo"
#const SIGNALING_URL = "ws://echo.websocket.events"
#const SIGNALING_URL = "wss://signaling-server-webrtc-demo.glitch.me"
var self_id = str(randi() % 10000)
var is_host = false
var is_signaling_connected = false

func _ready():
	randomize()
	chat_log.append_text("🪪 Your ID: %s\n" % self_id)
	set_process(true)

	send_button.pressed.connect(_on_send_pressed)
	chat_input.text_submitted.connect(_on_text_submitted)
	host_button.pressed.connect(_host_game)
	join_button.pressed.connect(_join_game)

	get_tree().get_multiplayer().peer_connected.connect(_on_peer_connected)
	get_tree().get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)

func _process(_delta):
	match signaling.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			print("🔄 WebSocket connecting...")
		WebSocketPeer.STATE_OPEN:
			signaling.poll()
			while signaling.get_available_packet_count() > 0:
				var msg = signaling.get_packet().get_string_from_utf8()
				_handle_signaling_message(msg)
		WebSocketPeer.STATE_CLOSING:
			print("⚠️ WebSocket closing...")
		WebSocketPeer.STATE_CLOSED:
			if is_signaling_connected:
				chat_log.append_text("❌ WebSocket closed unexpectedly.\n")
				is_signaling_connected = false


func _connect_to_signaling():
	var err = signaling.connect_to_url(SIGNALING_URL)
	if err != OK:
		chat_log.append_text("❌ Failed to connect to signaling server\n")
	else:
		is_signaling_connected = true
		chat_log.append_text("🌐 Connecting to signaling...\n")

func _host_game():
	is_host = true
	_connect_to_signaling()

func _join_game():
	is_host = false
	_connect_to_signaling()

func _handle_signaling_message(msg: String):
	chat_log.append_text("[Signal] %s\n" % msg)
	if msg.begins_with("JOIN:"):
		if is_host:
			var peer_id = msg.substr(5)
			_start_host_offer(peer_id)
	elif msg.begins_with("OFFER:"):
		var parts = msg.substr(6).split("|", false, 2)
		var peer_id = parts[0]
		var sdp = parts[1]
		_receive_offer(peer_id, sdp)
	elif msg.begins_with("ANSWER:"):
		var parts = msg.substr(7).split("|", false, 2)
		var peer_id = parts[0]
		var sdp = parts[1]
		_receive_answer(peer_id, sdp)
	elif msg.begins_with("ICE:"):
		var parts = msg.substr(4).split("|", false, 2)
		var peer_id = parts[0]
		var candidate = parts[1]
		_receive_ice(peer_id, candidate)

func _start_host_offer(peer_id):
	var peer := WebRTCPeerConnection.new()
	peer.initialize(rtc_config)
	peer.session_description_created.connect(_on_sdp_created.bind(peer_id))
	peer.ice_candidate_created.connect(_on_ice_candidate.bind(peer_id))
	peer.create_offer()
	webrtc.add_peer(peer, int(peer_id))
	peer_map[peer_id] = peer

func _receive_offer(peer_id, sdp):
	var peer := WebRTCPeerConnection.new()
	peer.initialize(rtc_config)
	peer.session_description_created.connect(_on_sdp_created.bind(peer_id))
	peer.ice_candidate_created.connect(_on_ice_candidate.bind(peer_id))
	peer.set_remote_description("offer", sdp)
	peer.create_answer()
	webrtc.add_peer(peer, int(peer_id))
	peer_map[peer_id] = peer

func _receive_answer(peer_id, sdp):
	if peer_map.has(peer_id):
		peer_map[peer_id].set_remote_description("answer", sdp)

func _receive_ice(peer_id, candidate):
	if peer_map.has(peer_id):
		peer_map[peer_id].add_ice_candidate(candidate)

func _on_sdp_created(type: String, sdp: String, peer_id):
	signaling.send_text("%s:%s|%s" % [type.to_upper(), str(peer_id), sdp])

func _on_ice_candidate(mid: String, index: int, candidate: String, peer_id):
	signaling.send_text("ICE:%s|%s" % [str(peer_id), candidate])

func _on_send_pressed():
	_send_message(chat_input.text)

func _on_text_submitted(text):
	_send_message(text)

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
	var name = "Client %s" % peer_id if peer_id != 1 else "Host"

	chat_log.push_color(Color.SKY_BLUE)
	chat_log.append_text("%s: " % name)
	chat_log.pop()
	chat_log.append_text(msg + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count())

func _on_peer_connected(id):
	chat_log.append_text("🔌 Peer %d connected.\n" % id)
	get_tree().get_multiplayer().multiplayer_peer = webrtc

func _on_peer_disconnected(id):
	chat_log.append_text("❌ Peer %d disconnected.\n" % id)
