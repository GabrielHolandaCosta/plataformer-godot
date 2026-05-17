extends EnemyBase

@export var walk_speed: float = 38.0
@export var max_hp: int = 2
# Quando true, o esqueleto persegue o player em vez de patrulhar.
# É ligado pelo Necromancer nos esqueletos invocados, pra eles correrem
# atrás do herói em vez de ficarem batendo a cara em parede.
@export var follow_player: bool = false
@export var chase_speed: float = 55.0

const FADE_DELAY    := 1.4
const FADE_DURATION := 0.6

var hp: int
var is_stunned: bool = false


func _ready() -> void:
	super._ready()
	hp = max_hp
	move_speed = walk_speed
	if anim is AnimatedSprite2D:
		(anim as AnimatedSprite2D).play("walk")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	if is_dead:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		move_and_slide()
		return
	if is_stunned:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		move_and_slide()
		return

	if follow_player:
		_chase_player(delta)
	else:
		flip_direction()
		movement(delta)


func _chase_player(delta: float) -> void:
	var p := _get_player()
	if p == null:
		flip_direction()
		movement(delta)
		return

	# Vira pra direção do player.
	var dir_to_player: float = signf(p.global_position.x - global_position.x)
	if dir_to_player != 0.0 and int(dir_to_player) != direction:
		direction = int(dir_to_player)
		if wall_detector:
			wall_detector.scale.x *= -1
		_update_visual_direction()

	# Pára se tem parede na frente OU se está prestes a cair de uma plataforma.
	# Sem isso o esqueleto fica travado pulando contra a parede / cai do mapa.
	var blocked_wall := false
	if wall_detector and wall_detector.is_colliding():
		blocked_wall = true
	if not blocked_wall and is_on_wall():
		blocked_wall = true

	var ledge_ahead := false
	if ground_detector and is_on_floor():
		ground_detector.position.x = ledge_ray_forward * float(direction)
		ground_detector.target_position = Vector2(0, ledge_ray_depth)
		ground_detector.force_raycast_update()
		if not ground_detector.is_colliding():
			ledge_ahead = true

	if blocked_wall or ledge_ahead:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	else:
		var target_speed: float = float(direction) * chase_speed
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	move_and_slide()


func _get_player() -> Node2D:
	if Globals.player != null and is_instance_valid(Globals.player):
		return Globals.player as Node2D
	var nodes: Array = get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		return nodes[0] as Node2D
	return null


func take_stomp_damage() -> void:
	if is_dead or is_stunned:
		return
	hp -= 1
	if hp <= 0:
		die()
	else:
		_play_hit()


func _play_hit() -> void:
	is_stunned = true
	var asp := anim as AnimatedSprite2D
	if asp:
		asp.play("hit")
		var sf: SpriteFrames = asp.sprite_frames
		var duration := float(sf.get_frame_count("hit")) / maxf(sf.get_animation_speed("hit"), 0.01)
		await get_tree().create_timer(duration + 0.05).timeout
	else:
		await get_tree().create_timer(0.5).timeout

	if not is_instance_valid(self) or is_dead:
		return
	is_stunned = false
	if anim is AnimatedSprite2D:
		(anim as AnimatedSprite2D).play("walk")


func die() -> void:
	if is_dead:
		return
	is_dead = true
	is_stunned = false
	_disable_hitbox_collision()
	collision.set_deferred("disabled", true)
	velocity = Vector2.ZERO

	var asp := anim as AnimatedSprite2D
	if asp:
		asp.play("hurt")
		var sf: SpriteFrames = asp.sprite_frames
		var anim_duration := float(sf.get_frame_count("hurt")) / maxf(sf.get_animation_speed("hurt"), 0.01)
		await get_tree().create_timer(anim_duration + FADE_DELAY).timeout
	else:
		await get_tree().create_timer(FADE_DELAY).timeout

	_fade_and_free()


func _fade_and_free() -> void:
	if not is_instance_valid(self):
		return
	var tw := create_tween()
	tw.tween_property(anim, "modulate:a", 0.0, FADE_DURATION)
	await tw.finished
	if not is_instance_valid(self):
		return
	Globals.score += enemy_score
	queue_free()


func _on_anim_animation_finished(_anim_name: StringName = "") -> void:
	pass


func _update_visual_direction() -> void:
	if anim is AnimatedSprite2D:
		(anim as AnimatedSprite2D).flip_h = direction == -1
