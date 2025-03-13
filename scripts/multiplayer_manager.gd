extends Node

@export var player_scene: PackedScene  # ← This must be above all functions!

func _ready():
	var peer = ENetMultiplayerPeer.new()
	var is_host := true  # Toggle between true (host) and false (client)

	if is_host:
		peer.create_server(12345, 2)
		print("Server started on port 12345")
	else:
		peer.create_client("127.0.0.1", 12345)
		print("Client connecting to localhost...")

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)

	# Wait until peer ID is ready before spawning
	call_deferred("_spawn_self")

func _spawn_self():
	var id = multiplayer.get_unique_id()
	print("Spawning local player with ID:", id)

	if player_scene == null:
		print("❌ ERROR: player_scene is null — did you assign it in the editor?")
		return

	var player = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	player.position = Vector2(-272 + (id * 10), 31)
	add_child(player)

func _on_peer_connected(id: int) -> void:
	print("Peer connected:", id)

	if id == multiplayer.get_unique_id():
		return  # Already spawned yourself

	var player = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	player.position = Vector2(-272 + (id * 10), 31)
	add_child(player)
