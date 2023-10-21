extends Area2D

export var has_ring := false

func _ready():
	return


func _process(_delta):
	return
#	if get_parent().find_node("Player"):
#		rotation = get_parent().find_node("Player").rotation
#	else:
#		rotation = get_parent().rotation


func _on_SpringSphere_body_entered(body):
	if not body.get_collision_layer_bit(0): return
	elif get_parent().initial_timer: return
	body.reverse_velocity()
	body.find_node("SFXPlayer").stream = load("res://assets/sfx/S3K_bumper.wav")
	body.find_node("SFXPlayer").play()
