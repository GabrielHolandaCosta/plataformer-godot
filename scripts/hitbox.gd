extends Area2D

# Caixa de stomp (acima da cabeça do inimigo).
# Quando o player encosta:
#   1) Sempre ricocheteia o player pra cima — assim ele nunca fica parado
#      em cima do inimigo (mesmo se o pai estiver invulnerável).
#   2) Aplica dano somente se o pai estiver em estado válido pra receber.
#      Estados que bloqueiam o dano: is_dead, is_invulnerable, is_stunned,
#      dialog_active.

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	var p = get_parent()

	# Se o pai está morto ou em diálogo, ignora completamente — não faz
	# sentido nem ricochete.
	if p.get("is_dead") == true:
		return
	if p.get("dialog_active") == true:
		return

	# Ricochete sempre, pra impedir que o player fique pousado em cima.
	body.velocity.y = body.JUMP_VELOCITY

	# Dano só se o pai pode receber.
	if p.get("is_invulnerable") == true:
		return
	if p.get("is_stunned") == true:
		return

	if p.has_method("take_stomp_damage"):
		p.take_stomp_damage()
	elif p.has_method("die"):
		p.die()
