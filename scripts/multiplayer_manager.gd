extends Node

@export var player_scene: PackedScene  # Reference to the player scene

var is_host := false  # Set to false for client

func _ready():
	var peer = ENetMultiplayerPeer.new()

	if is_host:
		peer.create_server(12345, 2)  # Start the server
		print("Server started on port 12345")
	else:
		peer.create_client("127.0.0.1", 12345)  # Connect to server (localhost)
		print("Client connecting to localhost...")

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)

	call_deferred("_spawn_self")  # Spawn the player after network setup

func _spawn_self():
	var id = multiplayer.get_unique_id()
	print("Spawning local player with ID:", id)

	if player_scene == null:
		print("❌ ERROR: player_scene is null — did you assign it in the editor?")
		return

	var player = player_scene.instantiate()
	player.position = Vector2(-172 + (id * 10), 31)  # Position based on ID
	add_child(player)

func _on_peer_connected(id: int) -> void:
	print("Peer connected:", id)

	if id == multiplayer.get_unique_id():
		return  # Skip spawning the local player again

	var player = player_scene.instantiate()
	player.position = Vector2(-272 + (id * 10), 31)  # Spawn remote player at different position
	add_child(player)
