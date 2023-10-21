extends Area2D


func _ready():
	pass

func _on_Emerald_body_entered(body):
	if not body.get_collision_layer_bit(0): return
	body.start_quit(true)
	get_parent().find_node("MakeSFX").stream = load("res://assets/sfx/S3K_failure.wav")
	get_parent().find_node("MakeSFX").play()
