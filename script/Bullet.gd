extends CharacterBody2D

const SPEED = 500.0

var direction : Vector2

func _ready() -> void:
	direction = Vector2(1,0).rotated(rotation)

func _physics_process(delta):
	# Add the gravity.
	velocity = SPEED * direction
	if not is_on_floor():
		velocity += get_gravity() * 1 * delta
	
	for i in get_slide_collision_count():
		queue_free()

	move_and_slide()
