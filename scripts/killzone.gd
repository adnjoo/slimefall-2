extends Area2D

@onready var timer = $Timer
@onready var hurt_sound = $HurtSound  # Reference to the AudioStreamPlayer node

func _on_body_entered(body: Node2D) -> void:
	print("You died.")
	hurt_sound.play()
	
	if body.is_in_group("Player"):
		LivesUI.lose_life()
	
	Engine.time_scale = 0.5
	body.get_node("CollisionShape2D").queue_free()
	timer.start()


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
