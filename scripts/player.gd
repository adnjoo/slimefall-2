extends CharacterBody2D

var GRAVITY = Globals.GRAVITY
const SPEED = 100.0
const JUMP_VELOCITY = -350.0
var can_move = true  # Controls whether player input is allowed

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO  # Stop movement
		animated_sprite.play("idle")  # Optionally play idle animation
		move_and_slide()
		return
	
	# Add gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction for horizontal movement.
	var direction = Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_on_floor():
		if Input.is_action_pressed("crouch"):
			animated_sprite.play("crouch")
		elif direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	# Apply movement	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Apply movement.
	move_and_slide()

func disable_controls():
	can_move = false

func _ready():
	can_move = true  # Re-enable player movement when the level is loaded
