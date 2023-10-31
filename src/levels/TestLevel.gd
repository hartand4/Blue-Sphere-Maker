extends Node2D


export var CHECKER_SIZE := 192
export var BOARD_SIZE := 6144

export var initial_timer := 3
export var ending_timer := 0

var list_of_spheres = []

export var global_blue_count := 1

export var max_rings := 16

var attempted_to_convert_to_rings = []

export var GAME_PAUSED := false

var temp_playback_position

var palette := 0

export var enable_3D := true

var sphere_to_ring_dict = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.perfect = false
	
	sphere_to_ring_dict = {}
	
	Globals.load_level(Globals.current_level_number)
	
	if Globals.loaded_level_data:
		setup_level(Globals.loaded_level_data)
	
	for child in get_children():
		if child.has_method("get_collision_layer") and child.get_collision_layer():
			var half_length_vector = Vector2(CHECKER_SIZE/2.0, CHECKER_SIZE/2.0)
			child.global_position = ((child.global_position-half_length_vector)/CHECKER_SIZE).round()*CHECKER_SIZE + half_length_vector
	
	#call_deferred("loop_maker")

func _process(_delta):
	if initial_timer > 0:
		initial_timer -= 1
		if initial_timer == 2:
			setup_sphere_placements()
			count_blues()
			$BackgroundMusic.playing = true
			$Player/Collision.disabled = false
		return
	
	if $BackgroundMusic.get_playback_position() > 225.663:
		$BackgroundMusic.seek($BackgroundMusic.get_playback_position() - 50.870)
	
	if global_blue_count == 0 and ending_timer <= 0:
		ending_timer = 480
		$MakeSFX.stream = load("res://assets/sfx/S3K_win.wav")
		$MakeSFX.play()
		$Player.lock_controls(true)
		return
	elif ending_timer > 0:
		ending_timer -=1
		do_ending_bit()
	
	if $Player.quitting_animation > 0:
		find_node("BackgroundMusic").volume_db -= 0.5

func setup_sphere_placements():
	list_of_spheres = []
	
	for i in self.get_children():
		if i.has_method("get_collision_layer"):
			if (i.get_collision_layer_bit(1) and i.active and i.has_ring) or (
				i.get_collision_layer_bit(2) and i.active and i.has_ring) or (
				i.get_collision_layer_bit(3) and i.has_ring) or (
				i.get_collision_layer_bit(4) and i.has_ring):
				list_of_spheres += [[i, null, null, null, null, null, null, null, null]]
	
	for b in list_of_spheres:
		for b2 in list_of_spheres:
			var blue = b[0]
			var blue2 = b2[0]
			var potential_index = 0
			if blue == blue2: pass
			if blue2.position.x == blue.position.x - CHECKER_SIZE or (
				blue2.position.x == blue.position.x - CHECKER_SIZE + BOARD_SIZE):
				potential_index = 41
			elif blue2.position.x == blue.position.x:
				potential_index = 66
			elif blue2.position.x == blue.position.x + CHECKER_SIZE or (
				blue2.position.x == blue.position.x + CHECKER_SIZE - BOARD_SIZE):
				potential_index = 148
			
			if blue2.position.y == blue.position.y - CHECKER_SIZE or (
				blue2.position.y == blue.position.y - CHECKER_SIZE + BOARD_SIZE):
				potential_index = potential_index&7
			elif blue2.position.y == blue.position.y:
				potential_index = potential_index&24
			elif blue2.position.y == blue.position.y + CHECKER_SIZE or (
				blue2.position.y == blue.position.y + CHECKER_SIZE - BOARD_SIZE):
				potential_index = potential_index&224
			else:
				potential_index = 0
			
			if potential_index > 0:
				b[log2(potential_index)+1] = blue2


func log2(x):
	return int(log(x) / log(2))

func check_for_closed_shape():
	var queue = []
	
	var blue_amount = 0
	
	for sphere in list_of_spheres:
		if sphere_type(sphere[0]) in [0,1,2] and sphere[0].get("has_ring"):
			queue += [sphere + [-1]]
		
		if sphere_type(sphere[0]) == 0 and sphere[0].has_ring:
			blue_amount += 1
	
	# Perform iterative search over all non-red spheres
	while queue.size() > 0 and blue_amount > 0:
		var current_item = queue.pop_front()
		
		#print("%s, %s left" % [current_item[0], blue_amount])
		
		# If a full loop has passed without the queue size changing, it's not going to change -> Done
		if current_item[9] == queue.size() + 1 and sphere_type(current_item[0]) == 0:
			print('TURN TO RINGS')
			$MakeSFX.play()
			attempted_to_convert_to_rings = []
			turn_to_rings(current_item.slice(0,8), true)
			return
		
		# Check all current item's surroundings
		var integrity = true
		for i in range(8):
			var adjacent_item = get_queue_item(queue, current_item[i+1])
			
			# If current item is adjacent to empty space (or connected to it), remove from queue
			if adjacent_item.size() == 0 and sphere_type(current_item[0]) != 1:
				integrity = false
		
		current_item[9] = queue.size() + 1
		
		if integrity:
			#print('Okay, no violations')
			queue += [current_item]
		elif sphere_type(current_item[0]) == 0:
			blue_amount -= 1

func sphere_type(sphere):
	if sphere.has_method("change_to_red"):
		if sphere.get_collision_layer_bit(1):
			return 0
		return 1
	if sphere.get_collision_layer_bit(3) or sphere.get_collision_layer_bit(4):
		return 2
	return -1

func get_queue_item(queue, node):
	if node == null: return []
	for item in queue:
		if node == item[0]: return item
	return []

func turn_to_rings(item, original=false):
	if sphere_type(item[0]) == 1:
		if item[0].is_active():
			item[0].turn_to_ring()
			var new_ring = sphere_to_ring_dict[item[0]]
			new_ring.active = true
			$FloorView/SpriteEffects.add_new_sprite(new_ring)
		return
	elif sphere_type(item[0]) == 0 and item[0].is_active():
		item[0].turn_to_ring()
		var new_ring = sphere_to_ring_dict[item[0]]
		new_ring.active = true
		$FloorView/SpriteEffects.add_new_sprite(new_ring)
		global_blue_count -= 1
	else:
		if item in attempted_to_convert_to_rings: return
		attempted_to_convert_to_rings += [item]
	for i in range(8):
		if get_queue_item(list_of_spheres, item[i+1]) != [] and (
			(not item[i+1].has_method("is_active") or item[i+1].is_active()) and
			(item[i+1] in sphere_to_ring_dict or sphere_type(item[i+1]) > 1)):
			call_deferred("turn_to_rings", get_queue_item(list_of_spheres, item[i+1]) )
	
	if !original: return
	
	setup_sphere_placements()
	
	if not enable_3D:
		return
	for child in get_children():
		if child is Area2D or child is Sprite:
			child.visible = false

# Unused
func loop_maker():
	var everything_list = get_children()
	for i in everything_list:
		if i == $Player: pass
		else:
			for j in range(8):
				if i is TextureRect:
					var new_thing = i.duplicate()
					new_thing.rect_position.x = BOARD_SIZE if j in [2,4,7] else -BOARD_SIZE if j in [0,3,5] else 0
					new_thing.rect_position.y = BOARD_SIZE if j >= 5 else -BOARD_SIZE if j <= 2 else 0
					i.call_deferred("add_child", new_thing)
				elif i is AudioStreamPlayer or i is CanvasLayer: pass
				else:
					var new_thing = i.duplicate()
					
					new_thing.position.x = i.position.x + (BOARD_SIZE if j in [2,4,7] else -BOARD_SIZE if j in [0,3,5] else 0)
					new_thing.position.y = i.position.y + (BOARD_SIZE if j >= 5 else -BOARD_SIZE if j <= 2 else 0)
					
					if not is_position_in_bounds(new_thing.position):
						i.call_deferred("add_child", new_thing)
						new_thing.set_as_toplevel(true)

func count_blues():
	global_blue_count = 0
	for sphere in get_children():
		if sphere.has_method("get_collision_layer") and sphere != $Player and (
		sphere_type(sphere) == 0 and sphere.is_active()):
			global_blue_count += 1

func is_position_in_bounds(pos):
	return pos.x > -BOARD_SIZE/2.0 and pos.x < BOARD_SIZE/2.0 and (
		pos.y > -BOARD_SIZE/2.0 and pos.y < BOARD_SIZE/2.0)

func pause_game(paused):
	if paused:
		GAME_PAUSED = true
		temp_playback_position = $BackgroundMusic.get_playback_position()
		$BackgroundMusic.stop()
		return
	GAME_PAUSED = false
	$BackgroundMusic.play()
	$BackgroundMusic.seek(temp_playback_position)

func setup_level(data):
	for child in get_children():
		if child is Area2D:
			call_deferred("remove_child", child)
	
	max_rings = data['rings']
	palette = data['palette']
	$FloorView.set_palette(palette)
	
	for i in range(data['level'].size()):
		for j in range(data['level'][i].length()):
			var char_to_check = data['level'][i][j]
			var position_for_here = Vector2(j,i)*CHECKER_SIZE - Vector2(
				BOARD_SIZE/2.0 + CHECKER_SIZE/2.0, BOARD_SIZE/2.0 + CHECKER_SIZE/2.0)
			
			if char_to_check in ['B', 'R', 'b', 'r']:
				var sphere = load("res://src/scenes/BlueSphere.tscn").instance()
				if char_to_check == 'R' or char_to_check == 'r':
					sphere.start_blue = false
				self.add_child(sphere)
				sphere.set_as_toplevel(true)
				sphere.position = position_for_here
				sphere.visible = false
				
				if char_to_check == 'b' or char_to_check == 'r':
					sphere.has_ring = true
					var ring = load("res://src/scenes/Ring.tscn").instance()
					self.add_child(ring)
					ring.set_as_toplevel(true)
					ring.position = position_for_here
					ring.visible = false
					ring.active = false
					sphere_to_ring_dict[sphere] = ring
			elif char_to_check == 'Y' or char_to_check == 'y':
				var yellow = load("res://src/scenes/YellowSphere.tscn").instance()
				self.add_child(yellow)
				yellow.set_as_toplevel(true)
				yellow.position = position_for_here
				yellow.visible = false
				
				if char_to_check == 'y':
					yellow.has_ring = true
			elif char_to_check == 'S' or char_to_check == 's':
				var spring = load("res://src/scenes/SpringSphere.tscn").instance()
				self.add_child(spring)
				spring.set_as_toplevel(true)
				spring.position = position_for_here
				spring.visible = false
				
				if char_to_check == 's':
					spring.has_ring = true
			elif char_to_check == 'G':
				var ring = load("res://src/scenes/Ring.tscn").instance()
				self.add_child(ring)
				ring.set_as_toplevel(true)
				ring.position = position_for_here
				ring.visible = false
			elif char_to_check == 'P':
				$Player.position = position_for_here
				$Player.rotation_degrees = data["rotation"]
				$Player.set_camera_dir($Player.rotation)

func do_ending_bit():
	if ending_timer == 479:
		for child in get_children():
			if child is Area2D:
				if child.find_node("Collision"): child.find_node("Collision").disabled = true
				if child.find_node("CollisionBlue"): child.find_node("CollisionBlue").disabled = true
				if child.find_node("CollisionRed"): child.find_node("CollisionRed").disabled = true
		return
	
	if ending_timer == 420:
		$Player.set_game_speed(0.5, true)
		
		var camera_dir = $Player.get_turn_timer()[4]
		if camera_dir.x > 0 and $Player.position.x > 0:
			$Player.position.x -= BOARD_SIZE/2.0
		elif camera_dir.x < 0 and $Player.position.x < 0:
			$Player.position.x += BOARD_SIZE/2.0
		if camera_dir.y > 0 and $Player.position.y > 0:
			$Player.position.y -= BOARD_SIZE/2.0
		elif camera_dir.y < 0 and $Player.position.y < 0:
			$Player.position.y += BOARD_SIZE/2.0
		return
	
	if 330 <= ending_timer and ending_timer <= 360:
		$BackgroundMusic.volume_db -= 0.5
		if ending_timer == 330:
			var new_emerald = load("res://src/scenes/Emerald.tscn").instance()
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			new_emerald.find_node("Sprite").frame = rng.randi_range(0,6)
			
			add_child(new_emerald)
			new_emerald.position = $Player.position + $Player.get_turn_timer()[4]*CHECKER_SIZE*5.5
			
			var half_length_vector = Vector2(CHECKER_SIZE/2.0, CHECKER_SIZE/2.0)
			new_emerald.global_position = ((new_emerald.global_position-half_length_vector)/CHECKER_SIZE).round()*CHECKER_SIZE + half_length_vector
			
			print("%s %s" % [$Player.position, new_emerald.position])
			
			$FloorView/SpriteEffects.add_new_sprite(new_emerald)
			
			$SFXUniversal.stream = load("res://assets/sfx/S3K_emerald.mp3")
			$SFXUniversal.play()
			$BackgroundMusic.stop()
		return
