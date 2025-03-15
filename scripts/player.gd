extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -400.0
@export var player_id: int = -1  # Assigned by ChatRoom

func _ready():
	# Disable control if this is not the local player
	if player_id != GDSync.get_client_id():
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED

		# Flip sprite based on direction
		$AnimatedSprite2D.scale.x = -1 if direction < 0 else 1

		# Play run animation
		if not $AnimatedSprite2D.is_playing() or $AnimatedSprite2D.animation != "run":
			$AnimatedSprite2D.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

		# Play idle animation
		if not $AnimatedSprite2D.is_playing() or $AnimatedSprite2D.animation != "idle":
			$AnimatedSprite2D.play("idle")

	move_and_slide()
