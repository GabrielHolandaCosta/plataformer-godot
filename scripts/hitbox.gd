extends Area2D

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.velocity.y = body.JUMP_VELOCITY
		var p = get_parent()
		if p.has_method("take_stomp_damage"):
			p.take_stomp_damage()
		elif p.has_method("die"):
			p.die()
