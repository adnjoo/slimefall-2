extends CharacterBody2D

var GRAVITY = Globals.GRAVITY
const SPEED = 100.0
const JUMP_VELOCITY = -350.0
var can_move = true

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	can_move = true
	set_multiplayer_authority(name.to_int())  # Assume the name is the peer_id
	set_process(multiplayer.is_server() or is_multiplayer_authority())

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return  # Only let the owner control

	if not can_move:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
		move_and_slide()
		return

	# Add gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var direction = Input.get_axis("move_left", "move_right")

	# Flip sprite
	animated_sprite.flip_h = direction < 0

	# Animations
	if is_on_floor():
		if Input.is_action_pressed("crouch"):
			animated_sprite.play("crouch")
		elif direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	# Apply horizontal movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	rpc("sync_position", global_position)

@rpc("unreliable")
func sync_position(pos: Vector2):
	if not is_multiplayer_authority():
		global_position = pos

func disable_controls():
	can_move = false
