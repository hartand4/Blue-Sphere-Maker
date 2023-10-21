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


func _on_YellowSphere_body_entered(body):
	if not body.get_collision_layer_bit(0): return
	body.start_spring_jump()
	$SFX.play()
