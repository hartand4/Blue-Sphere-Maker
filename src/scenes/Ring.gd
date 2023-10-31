extends Area2D

export var active := true

func _ready():
	pass


func _process(_delta):
	if (get_parent() and get_parent().get("GAME_PAUSED") != null and get_parent().GAME_PAUSED):
		$Sprite/AnimationPlayer.stop(false)
		return
	
	$Sprite/AnimationPlayer.play("Spin")
	$Collision.disabled = !active


func _on_Ring_body_entered(body):
	if not body.get_collision_layer_bit(0) or !active: return
	body.ring_count += 1
	get_parent().find_node("SFXUniversal").stream = load("res://assets/sfx/S3K_ring.wav")
	get_parent().find_node("SFXUniversal").play()
	get_parent().call_deferred("remove_child",self)
	#self.queue_free()

func unload():
	get_parent().remove_child(self)

func is_active():
	return active
