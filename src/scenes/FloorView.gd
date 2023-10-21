extends CanvasLayer


onready var player

var turn_timer := 0
var checker_parity := false
var last_checker_parity := false

var enable_3D = true

func _ready():
	if get_parent() and get_parent().find_node("Player"):
		player = get_parent().find_node("Player")
		enable_3D = get_parent().enable_3D
		if enable_3D:
			self.visible = true
			get_parent().find_node("Background").visible = false
			for child in get_parent().get_children():
				if "BlueSphere" in child.name or "Spring" in child.name or "YellowSphere" in child.name or "Ring" in child.name:
					child.visible = false
		else:
			self.visible = false
			$ParallaxBackground.visible = false


func _process(_delta):
	turn_timer = player.get_turn_timer()[0]
	var game_speed = player.get_turn_timer()[1]
	
	checker_parity = player.parity_of_position()
	
	var distance_to_cross = player.get_cross_distance()
	
	var CHECKER_SIZE = get_parent().CHECKER_SIZE
	
	$PlayerSprite.frame = player.find_node("Sprite").frame
	$PlayerSprite.position.y = 512 + player.get_height()
	$PlayerSprite.z_index = 241
	$Shadow.visible = $PlayerSprite.frame >= 8
	
	var quitting_animation = player.get_quitting_animation()
	if quitting_animation > 0:
		do_quit(quitting_animation)
		return
	
	if turn_timer <= 0:
		var frame_to_make = 8 - round(8.0*distance_to_cross / CHECKER_SIZE)
		if frame_to_make < 0: frame_to_make = 0
		elif frame_to_make > 7: frame_to_make = 7
		
		if player.get_turn_timer()[2] < 0:
			frame_to_make = 7-frame_to_make
		
		$Sprite.frame = frame_to_make if distance_to_cross > 0 else 0
		
		$Sprite.flip_h = checker_parity
		return
	
	# Sprite no flip, flip_frames false => left turn with true parity
	# Sprite no flip, flip_frames true => right turn false parity
	# Sprite flip, flip_frames false => right turn true parity
	# Sprite flip, flip_frames true => left turn false parity
	
	$Sprite.flip_h = false
	
	if turn_timer > 7:
		last_checker_parity = checker_parity
	
	var frame_to_make = 7 - round(7.0*turn_timer / int(-3*game_speed + 20) )
	if frame_to_make < 0: frame_to_make = 0
	elif frame_to_make > 6: frame_to_make = 6
	
	if not player.get_turn_timer()[3]:
		if last_checker_parity:
			frame_to_make += 8
	else:
		frame_to_make = 6 - frame_to_make
		if not last_checker_parity:
			frame_to_make += 8
	
	$Sprite.frame = frame_to_make + 8

func do_quit(quitting_animation):
	var frame_to_use = quitting_animation % 14
	frame_to_use = floor(frame_to_use)
	#print(frame_to_use)
	if frame_to_use >= 7:
		frame_to_use += 1
	$Sprite.frame = frame_to_use + 8

func set_palette(n):
	if n >= 0 and n <= 9:
		$Sprite.texture = load("res://assets/background/floors/FloorCurved%s.png" % (n+1))
		$ParallaxBackground/ParallaxLayer/SkyBG.texture = load("res://assets/background/floors/SkyBG%s.png" % (n+1))
