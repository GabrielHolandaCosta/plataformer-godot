extends Area2D


func _on_body_entered(body):
	if body.has_method("handle_death_zone"):
		body.handle_death_zone()
