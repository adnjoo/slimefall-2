extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -400.0
@export var player_id: int = -1  # Assigned by ChatRoom
var chat_room: Node = null

func _ready():
	# Disable control if this is not the local player
	if player_id != GDSync.get_client_id():
		set_physics_process(false)

	# Get reference to the ChatRoom node (adjust the path to your actual scene)
	chat_room = get_tree().get_root().get_node("ChatRoom")  # <-- update if needed

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		var dir_x = -1.0 if direction < 0 else 1.0
		$AnimatedSprite2D.scale.x = dir_x

		if not $AnimatedSprite2D.is_playing() or $AnimatedSprite2D.animation != "run":
			$AnimatedSprite2D.play("run")
			if chat_room:
				GDSync.call_func(chat_room.update_animation, [player_id, dir_x, "run"])
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

		if not $AnimatedSprite2D.is_playing() or $AnimatedSprite2D.animation != "idle":
			$AnimatedSprite2D.play("idle")
			if chat_room:
				GDSync.call_func(chat_room.update_animation, [player_id, $AnimatedSprite2D.scale.x, "idle"])

	move_and_slide()
