extends EnemyBase

@export var armored_speed: float = 30.0
@export var unarmored_speed: float = 65.0
@export var hurt_stun_time: float = 0.35

var is_armored: bool = true
var is_hurting: bool = false

@onready var anim_armored: AnimatedSprite2D = $anim_armored
@onready var hitbox_collision: CollisionShape2D = $hitbox/collision2
@onready var collision_unarmored: CollisionShape2D = $collision_unarmored

const HITBOX_OFFSET_ARMORED := Vector2(0, -31.0)
const HITBOX_OFFSET_UNARMORED := Vector2(0, -15.0)


func _ready() -> void:
	super._ready()
	move_speed = armored_speed
	if anim_armored:
		anim_armored.visible = true
		anim_armored.play("armored_walk")
	if anim is AnimatedSprite2D:
		(anim as AnimatedSprite2D).visible = false
	if hitbox_collision:
		hitbox_collision.position = HITBOX_OFFSET_ARMORED
	if collision:
		collision.disabled = false
	if collision_unarmored:
		collision_unarmored.disabled = true
	_update_visual_direction()


func _physics_process(delta: float) -> void:
	if is_dead:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		move_and_slide()
		return
	_apply_gravity(delta)
	if is_hurting:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		move_and_slide()
		return
	flip_direction()
	movement(delta)


func _update_visual_direction() -> void:
	var flip := direction == 1
	if anim_armored:
		anim_armored.flip_h = flip
	if anim is AnimatedSprite2D:
		(anim as AnimatedSprite2D).flip_h = flip


func take_stomp_damage() -> void:
	if is_dead:
		return
	if is_armored:
		_remove_armor()
	else:
		die()


func die() -> void:
	if is_dead:
		return
	if collision_unarmored:
		collision_unarmored.set_deferred("disabled", true)
	is_hurting = false
	if is_armored:
		is_armored = false
		if anim_armored:
			anim_armored.visible = false
		if anim is AnimatedSprite2D:
			(anim as AnimatedSprite2D).visible = true
	super.die()


func _remove_armor() -> void:
	if is_hurting:
		return
	is_hurting = true
	is_armored = false
	move_speed = unarmored_speed
	if anim_armored:
		anim_armored.visible = false
	if anim is AnimatedSprite2D:
		var asp := anim as AnimatedSprite2D
		asp.visible = true
		asp.play("hurt")
	if hitbox_collision:
		hitbox_collision.position = HITBOX_OFFSET_UNARMORED
	if collision:
		collision.set_deferred("disabled", true)
	if collision_unarmored:
		collision_unarmored.set_deferred("disabled", false)
	await get_tree().create_timer(hurt_stun_time).timeout
	if not is_instance_valid(self) or is_dead:
		return
	is_hurting = false
	if anim is AnimatedSprite2D:
		(anim as AnimatedSprite2D).play("walk")
