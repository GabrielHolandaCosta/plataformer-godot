extends CharacterBody2D

const SPEED = 190.0
const ACCELERATION = 900.0
const FRICTION = 1300.0
const AIR_ACCELERATION = 700.0
const AIR_FRICTION = 300.0
const JUMP_VELOCITY = -360.0
const FALL_GRAVITY_MULTIPLIER = 1.35
const LOW_JUMP_MULTIPLIER = 1.15
const KNOCKBACK_RECOVERY = 1800.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_jumping := false
var player_life := 10
var knockback_vector := Vector2.ZERO
var is_hurt := false

@onready var animation := $anim as AnimatedSprite2D
@onready var remote_transform := $remote as RemoteTransform2D


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		if velocity.y > 0:
			velocity.y += gravity * FALL_GRAVITY_MULTIPLIER * delta
		else:
			velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_hurt:
		velocity.y = JUMP_VELOCITY
		is_jumping = true

	# Make small jumps feel better when the jump button is released early.
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= LOW_JUMP_MULTIPLIER

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")

	if not is_hurt:
		if direction != 0:
			if is_on_floor():
				velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
			else:
				velocity.x = move_toward(velocity.x, direction * SPEED, AIR_ACCELERATION * delta)

			if direction > 0:
				animation.flip_h = false
			elif direction < 0:
				animation.flip_h = true
		else:
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, AIR_FRICTION * delta)

	# Apply knockback separately so it always works.
	velocity += knockback_vector
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, KNOCKBACK_RECOVERY * delta)

	move_and_slide()

	if is_on_floor():
		is_jumping = false
	else:
		is_jumping = true

	_update_animation_speed()
	_update_animation()


func _update_animation():
	if is_hurt:
		_play_animation("hurt")
		return

	if not is_on_floor():
		if velocity.y < 0:
			_play_animation("jump")
		else:
			_play_animation("fall")
		return

	if abs(velocity.x) > 10:
		_play_animation("run")
	else:
		_play_animation("idle")


func _update_animation_speed():
	if animation.animation == "run":
		var run_speed = clamp(abs(velocity.x) / SPEED, 0.8, 1.15)
		animation.speed_scale = run_speed
	else:
		animation.speed_scale = 1.0


func _play_animation(anim_name: String):
	if animation.animation != anim_name:
		animation.play(anim_name)


func _on_hurtbox_body_entered(body):
	if not body.is_in_group("enemies"):
		return

	if player_life <= 0:
		queue_free()
		return

	if $ray_right.is_colliding():
		take_damage(Vector2(-45, -55))
	elif $ray_left.is_colliding():
		take_damage(Vector2(45, -55))
	else:
		if animation.flip_h:
			take_damage(Vector2(45, -55))
		else:
			take_damage(Vector2(-45, -55))


func follow_camera(camera):
	var camera_path = camera.get_path()
	remote_transform.remote_path = camera_path


func take_damage(knockback_force := Vector2.ZERO, duration := 0.25):
	player_life -= 1
	is_hurt = true

	if player_life <= 0:
		queue_free()
		return

	if knockback_force != Vector2.ZERO:
		knockback_vector = knockback_force

	var damage_tween := get_tree().create_tween()
	damage_tween.parallel().tween_property(animation, "modulate", Color(1, 0.35, 0.35, 1), 0.08)
	damage_tween.parallel().tween_property(self, "knockback_vector", Vector2.ZERO, duration)

	await damage_tween.finished

	animation.modulate = Color(1, 1, 1, 1)
	is_hurt = false
