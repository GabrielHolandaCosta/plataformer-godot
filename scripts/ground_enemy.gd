extends EnemyBase


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_apply_gravity(delta)
	flip_direction()
	movement(delta)
