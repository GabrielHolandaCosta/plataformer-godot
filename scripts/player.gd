extends CharacterBody2D

const SPEED = 120.0
const ACCELERATION = 600.0
const FRICTION = 1300.0
const AIR_ACCELERATION = 700.0
const AIR_FRICTION = 300.0
# Pulo estilo retrô 2D: arco fixo na subida, sem “flutuar” por segurar o botão
const JUMP_VELOCITY = -255.0
# Só na queda um pouco mais forte (NES/SNES costumam fazer isso de leve)
const FALL_GRAVITY_MULTIPLIER = 1.22
# Soltar o pulo cedo = pulo baixo (único ajuste de altura, típico de Mario-like clássico)
const JUMP_CUT_MULTIPLIER = 0.5
const MAX_COINS_LOST_ON_HIT := 5

const COIN_DROP_SCENE := preload("res://prefabs/coin_rigid.tscn")

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_jumping := false
var is_hurted := false
var can_move := true

signal player_has_died()

@onready var animation := $anim as AnimatedSprite2D
@onready var remote_transform := $remote as RemoteTransform2D
@onready var ray_right := $ray_right
@onready var ray_left := $ray_left
@onready var jump_sfx = $jump_sfx as AudioStreamPlayer
@onready var destroy_sfx = preload("res://sounds/destroy_sfx.tscn")
@export var player_start_position: Node2D

func _physics_process(delta):
	if not can_move:
		# Player travado por diálogo/cutscene: zera velocidade horizontal,
		# mas mantém a gravidade pra ele aterrissar caso esteja no ar.
		velocity.x = 0
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
		move_and_slide()
		if is_on_floor():
			_play_animation("idle")
		else:
			_play_animation("fall" if velocity.y > 10 else "jump")
		return
		
	if not is_on_floor():
		if velocity.y > 0.0:
			velocity.y += gravity * FALL_GRAVITY_MULTIPLIER * delta
		else:
			velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_hurted:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		jump_sfx.play()

	if Input.is_action_just_released("ui_accept") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	var direction = Input.get_axis("ui_left", "ui_right")

	if not is_hurted:
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

	move_and_slide()

	for platform in range(get_slide_collision_count()):
		var collision = get_slide_collision(platform)
		if collision.get_collider().has_method("has_collided_with"):
			collision.get_collider().has_collided_with(collision, self)

	is_jumping = not is_on_floor()

	_update_animation_speed()
	_update_animation()


func _update_animation():
	if is_hurted:
		_play_animation("hurt")
		return

	if not is_on_floor():
		if velocity.y < -10:
			_play_animation("jump")
		elif velocity.y > 10:
			_play_animation("fall")
		else:
			_play_animation("jump")
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

	if body.get("is_dead"):
		return

	if is_hurted:
		return

	if body.is_in_group("Fireball"):
		body.queue_free()

	if ray_right.is_colliding():
		take_damage(Vector2(-180, -220))
	elif ray_left.is_colliding():
		take_damage(Vector2(180, -220))
	else:
		if animation.flip_h:
			take_damage(Vector2(180, -220))
		else:
			take_damage(Vector2(-180, -220))


func follow_camera(camera):
	var camera_path = camera.get_path()
	remote_transform.remote_path = camera_path


func lose_coins() -> void:
	var drop_count: int = mini(Globals.coins, MAX_COINS_LOST_ON_HIT)
	if drop_count <= 0:
		return
	Globals.coins -= drop_count
	var spawn_pos: Vector2 = global_position + Vector2(0.0, -10.0)
	var parent_node: Node = get_parent()
	for _i in drop_count:
		var coin_rb: RigidBody2D = COIN_DROP_SCENE.instantiate() as RigidBody2D
		coin_rb.global_position = spawn_pos
		parent_node.call_deferred("add_child", coin_rb)


func take_damage(knockback_force := Vector2.ZERO):
	if is_hurted:
		return

	Globals.player_life -= 1
	print("Vida do player: ", Globals.player_life)

	lose_coins()

	if Globals.player_life > 0:
		is_hurted = true
		velocity = knockback_force
		animation.modulate = Color(1, 0.35, 0.35, 1)

		await get_tree().create_timer(0.3).timeout

		animation.modulate = Color(1, 1, 1, 1)
		is_hurted = false
	else:
		emit_signal("player_has_died")
		queue_free()


func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and is_on_floor() and not is_hurted:
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			jump_sfx.play()
		elif not event.pressed and velocity.y < 0.0:
			velocity.y *= JUMP_CUT_MULTIPLIER


func _on_head_collider_body_entered(body):
	if body.has_method("break_sprite"):
		if body.hitbox_sfx:
			body.hitbox_sfx.play()

		body.hitpoints -= 1

		if body.hitpoints <= 0:
			play_destroy_sfx()
			body.break_sprite()
		else:
			if body.animation_player and body.animation_player.has_animation("hit"):
				body.animation_player.play("hit")

			if body.has_method("create_coin"):
				body.create_coin()


func play_destroy_sfx() -> void:
	var sound_sfx = destroy_sfx.instantiate()
	get_parent().add_child(sound_sfx)
	sound_sfx.play()
	await sound_sfx.finished
	sound_sfx.queue_free()
	
func handle_death_zone():
	Globals.player_life -= 1
	if Globals.player_life > 0:
		visible = false
		set_physics_process(false)

		await get_tree().create_timer(1.0).timeout
		global_position = player_start_position.global_position
		visible = true
		set_physics_process(true)
	else:
		visible = false
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
