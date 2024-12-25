extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -250.0

var syncSprite = true
var syncPos = Vector2(0, 0)
var syncRot = 0

@export var Bullet :PackedScene

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

func _physics_process(delta: float) -> void:
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Gun following mouse
		# Dapatkan posisi mouse di dalam viewport
		var mouse_pos = get_viewport().get_mouse_position()

		# Dapatkan ukuran viewport
		var viewport_rect = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)

		# Pastikan posisi mouse berada dalam jendela permainan
		if viewport_rect.has_point(mouse_pos):
			$GunRotation.look_at(mouse_pos)

		# Spawn bullet
		if Input.is_action_just_pressed("Fire"):
			fireBullet.rpc()

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			if direction == -1:
				$AnimatedSprite2D.flip_h = false
			else:
				$AnimatedSprite2D.flip_h = true
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
		
		syncSprite = $AnimatedSprite2D.flip_h
		syncPos = global_position
		syncRot = $GunRotation.rotation_degrees
	else:
		$AnimatedSprite2D.flip_h = syncSprite
		global_position = global_position.lerp(syncPos, .5)
		$GunRotation.rotation_degrees = syncRot

@rpc("any_peer", "call_local")
func fireBullet():
	var spawnedBullet = Bullet.instantiate()
	spawnedBullet.global_position = $GunRotation/BulletSpawn.global_position
	spawnedBullet.rotation_degrees = $GunRotation.rotation_degrees
	get_tree().root.add_child(spawnedBullet)
