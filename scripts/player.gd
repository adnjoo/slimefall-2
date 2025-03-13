extends CharacterBody2D

var GRAVITY = 1000
const SPEED = 100.0
const JUMP_VELOCITY = -350.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

func _ready():
	set_multiplayer_authority(multiplayer.get_unique_id())  # Set authority to unique ID

	if is_multiplayer_authority():
		camera.enabled = true  # Enable camera for the local player
	else:
		animated_sprite.modulate = Color(1, 1, 1, 0.5)  # Make remote players semi-transparent

	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		handle_input(delta)
		rpc("sync_position", global_position, true)  # Use "rpc" with 'unreliable' flag as true
	else:
		# Remote player: just animate without movement controls
		animated_sprite.play("idle")

	# Move the player (works for both local and remote)
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

	# Flip sprite
	animated_sprite.flip_h = direction < 0

	# Handle animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	# Horizontal velocity
	velocity.x = direction * SPEED

@rpc("unreliable")
func sync_position(pos: Vector2):
	if not is_multiplayer_authority():
		global_position = pos  # Update remote player's position
