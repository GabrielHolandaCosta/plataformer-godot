extends Area2D

var is_active = false
@onready var marker_2d = $Marker2D
@onready var anim = $anim 

func _on_body_entered(body):
	if body.name != "player" or is_active:
		return 
	activate_checkpoint()
	
func activate_checkpoint():
	Globals.current_checkpoint = marker_2d
	anim.play("raising")
	is_active = true


func _on_anim_animation_finished():
	if anim.animation == "raising":
		anim.play("checked")
