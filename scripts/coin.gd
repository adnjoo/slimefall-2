extends Area2D

@export var coin_id: String  # Unique ID for each coin

@onready var animation_player = $AnimationPlayer

func _ready():
	if GameManager.is_coin_collected(coin_id):
		queue_free()  # Remove coin if already collected

func _on_body_entered(_body: Node2D) -> void:
	animation_player.play("pickup")
	
	GameManager.collect_coin(coin_id)
	LivesUI.add_point()
