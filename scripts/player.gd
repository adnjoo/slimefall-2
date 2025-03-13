extends CharacterBody2D

var GRAVITY = Globals.GRAVITY
const SPEED = 100.0
const JUMP_VELOCITY = -350.0
var can_move = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

func _ready():
	can_move = true
	set_multiplayer_authority(name.to_int())  # Important for sync
	
	# Only enable camera if this is your player
	camera.enabled = is_multiplayer_authority()

	print("Spawned player with name:", name, " | Authority:", is_multiplayer_authority())

	# Optional: visually distinguish remote players
	if not is_multiplayer_authority():
		animated_sprite.modulate = Color(1, 1, 1, 0.5)  # semi-transparent
		var label = Label.new()
		label.text = "Remote"
		add_child(label)
		label.position = Vector2(0, -20)

	# Always run _physics_process (even for remote players)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("sync_position", global_position)

	if is_multiplayer_authority():
		handle_input(delta)
	else:
		# Remote player: still animate if needed
		animated_sprite.play("idle")


func handle_input(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement
	var direction = Input.get_axis("move_left", "move_right")

	# Flip
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

	# Horizontal velocity
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Sync position across network
	rpc("sync_position", global_position)

@rpc("unreliable")
func sync_position(pos: Vector2):
	if not is_multiplayer_authority():
		global_position = pos

func disable_controls():
	can_move = false
