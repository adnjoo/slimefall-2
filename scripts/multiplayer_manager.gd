# File: scripts/multiplayer_manager.gd
extends Node

var is_host := true  # manually toggle this to false when testing as client

func _ready():
	if is_host:
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(12345, 2)
		multiplayer.multiplayer_peer = peer
		print("Host started.")
	else:
		var peer = ENetMultiplayerPeer.new()
		peer.create_client("127.0.0.1", 12345)
		multiplayer.multiplayer_peer = peer
		print("Client connecting...")
