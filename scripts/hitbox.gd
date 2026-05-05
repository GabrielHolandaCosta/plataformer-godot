extends Area2D

# Caixa de stomp (acima da cabeça do inimigo).
# Quando o player encosta:
#   1) verifica se o pai está em estado que aceita dano (não morto / invulnerável /
#      atordoado / dialogando). Se não estiver, ignora — assim evita que o player
#      fique pulando infinitamente em cima de um boss em HURT e o mate de graça.
#   2) ricochete no player + chama take_stomp_damage() (ou die() como fallback).

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	var p = get_parent()

	# Estados que travam o stomp. Usamos get() pra funcionar mesmo quando o pai
	# não declarou a variável (retorna null/false e a checagem segue).
	if p.get("is_dead") == true:
		return
	if p.get("is_invulnerable") == true:
		return
	if p.get("is_stunned") == true:
		return
	if p.get("dialog_active") == true:
		return

	body.velocity.y = body.JUMP_VELOCITY
	if p.has_method("take_stomp_damage"):
		p.take_stomp_damage()
	elif p.has_method("die"):
		p.die()
