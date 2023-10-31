extends Area2D

export var start_blue = true
export var has_ring = false

var active = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if not start_blue:
		change_to_red()
		if find_node("CollisionBlue"):
			$CollisionBlue.disabled = true

func _process(_delta):
	return
#	if get_parent().find_node("Player"):
#		rotation = get_parent().find_node("Player").rotation
#	else:
#		rotation = get_parent().rotation



func _on_BlueSphere_body_entered(body):
	if not body.get_collision_layer_bit(0): return
	if self.get_collision_layer_bit(1):
		call_deferred("change_to_red")
		find_node("SFXPlayer").stream = load("res://assets/sfx/S3K_bluesphere.wav")
		find_node("SFXPlayer").play()
		
		if get_parent().has_method("check_for_closed_shape") and has_ring:
			get_parent().call_deferred("check_for_closed_shape")
		return
	elif self.get_collision_layer_bit(2):
		body.start_quit(false)
		find_node("SFXPlayer").stream = load("res://assets/sfx/S3K_failure.wav")
		find_node("SFXPlayer").play()
		return

func _on_BlueSphere_body_exited(body):
	if not body.get_collision_layer_bit(0): return
	call_deferred("disable_blue")

func change_to_red():
	self.collision_layer = 4
	$Sprite.texture = load("res://assets/background/Red Sphere.png")
	if find_node("CollisionRed"):
		$CollisionRed.disabled = false
	
	if get_parent() != null and get_parent().has_method("count_blues") and start_blue:
		get_parent().count_blues()

func disable_blue():
	if $CollisionBlue:
		$CollisionBlue.disabled = true

func unload():
	if get_parent():
		get_parent().remove_child(self)
		#self.queue_free()

func is_active():
	return active

func turn_to_ring():
	active = false
	call_deferred("setup_ring")
	return
	
	#call_deferred("unload")

func setup_ring():
	if self.find_node("CollisionBlue"):
		$CollisionBlue.disabled = true
	if self.find_node("CollisionRed"):
		$CollisionRed.disabled = true
	$Sprite.visible = false
