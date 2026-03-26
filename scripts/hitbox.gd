extends Area2D

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("pisou no inimigo")
		body.velocity.y = body.JUMP_VELOCITY
		get_parent().die()
