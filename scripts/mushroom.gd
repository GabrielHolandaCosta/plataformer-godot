extends EnemyBase

@export var walk_speed: float = 45.0
@export var max_hp: int = 3

const FADE_DELAY    := 2.0
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
	flip_direction()
	movement(delta)


# --- Dano por pisada ---

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


# --- Morte: fica no chão, espera a animação, depois faz fade out ---

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
	collision.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(anim, "modulate:a", 0.0, FADE_DURATION)
	await tw.finished
	if not is_instance_valid(self):
		return
	Globals.score += enemy_score
	queue_free()


# Impede que a base chame kill_and_score() automaticamente ao terminar a animação.
func _on_anim_animation_finished(_anim_name: StringName = "") -> void:
	pass
