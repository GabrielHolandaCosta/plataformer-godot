extends RigidBody2D

## Se true: moeda largada ao levar dano (impulso moderado + bloqueio de pickup curto).
## Se false: moeda da break-box — usa manual_impulse (perto do spawn).
var hurt_style_drop: bool = true
var manual_impulse: Vector2 = Vector2.ZERO

const PICKUP_BLOCK_TIME := 0.5


func _ready() -> void:
	if has_node("coin"):
		$coin.set_process(false)
	if hurt_style_drop:
		_block_pickup_temporarily()
		call_deferred("_apply_hurt_drop_impulse")
	elif manual_impulse != Vector2.ZERO:
		call_deferred("_apply_manual_impulse")


func _block_pickup_temporarily() -> void:
	var cs := get_node_or_null("coin/collision") as CollisionShape2D
	if cs:
		cs.set_deferred("disabled", true)
	await get_tree().create_timer(PICKUP_BLOCK_TIME).timeout
	if is_instance_valid(cs):
		cs.set_deferred("disabled", false)


func _apply_hurt_drop_impulse() -> void:
	apply_central_impulse(
		Vector2(randf_range(-55.0, 55.0), randf_range(-100.0, -40.0))
	)


func _apply_manual_impulse() -> void:
	apply_central_impulse(manual_impulse)
