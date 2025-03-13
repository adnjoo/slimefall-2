extends CharacterBody2D

var SPEED = 100.0
var GRAVITY = 1000
const JUMP_VELOCITY = -350.0

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Only the player with authority can control the player (local player or host)
	if is_multiplayer_authority():
		set_physics_process(true)  # Enable movement controls for the player with authority
	else:
		set_physics_process(false)  # Disable movement for remote players

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		handle_input(delta)
		rpc("sync_position", global_position)  # Sync position across the network
	move_and_slide()

func handle_input(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	# Animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

@rpc("unreliable")
func sync_position(pos: Vector2):
	global_position = pos  # Update position for remote players
