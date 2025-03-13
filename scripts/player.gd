extends CharacterBody2D

var SPEED = 100.0
var GRAVITY = 1000
const JUMP_VELOCITY = -350.0

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	handle_input(delta)
	move_and_slide()

	# Sync position to all players
	rpc("sync_position", global_position)

func handle_input(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	# Play animations based on input
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
