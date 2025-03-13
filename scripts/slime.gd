extends Node2D

var GRAVITY = Globals.GRAVITY
const SPEED = 60
var velocity = Vector2.ZERO  # Add velocity to handle gravity
var direction = 1

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_down: RayCast2D = $RayCastDown
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	position.x += direction * SPEED * delta

func _physics_process(delta: float) -> void:
	if not ray_cast_down.is_colliding():  # If not touching the ground
		velocity.y += GRAVITY * delta  # Apply gravity
	else:
		velocity.y = 0  # Reset gravity when on the ground

	position.y += velocity.y * delta  # Apply vertical movement
