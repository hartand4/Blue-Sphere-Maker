extends Node2D


onready var level
onready var player

var GAME_PAUSED := false

var CHECKER_SIZE := 1
var BOARD_SIZE := 12

var FOV = 60
var sqrtFOV = 8

var list_of_sprites = []

func _ready():
	if get_parent() and get_parent().get_parent():
		level = get_parent().get_parent()
		if level.get("CHECKER_SIZE"):
			CHECKER_SIZE = level.CHECKER_SIZE
			BOARD_SIZE = level.BOARD_SIZE
			FOV = 60*CHECKER_SIZE*CHECKER_SIZE
			sqrtFOV = sqrt(FOV)
	if level.find_node("Player"):
		player = level.find_node("Player")


func _process(_delta):
	if not get_parent().get_parent().enable_3D: return
	if level == null or player == null: return
	
	if get_parent().get_parent().initial_timer == 1:
		make_sprite_list(true)
	
	for sprite in list_of_sprites:
		if sprite[1] == null or (sprite[1].has_method("is_active") and not sprite[1].is_active()):
			make_sprite_list(false)
			break
	
	if get_parent().get_parent().ending_timer > 360 and get_parent().get_parent().ending_timer < 479:
		for sprite in list_of_sprites:
			sprite[0].frame = sprite[1].find_node("Sprite").frame
			sprite[0].texture = sprite[1].find_node("Sprite").texture
			sprite[0].position.y = sprite[0].position.y - 15 if get_parent().get_parent().ending_timer > 420 else -500
		return
	elif get_parent().get_parent().ending_timer > 0 and get_parent().get_parent().ending_timer <= 360:
		for sprite in list_of_sprites:
			sprite[0].visible = sprite[1].get_collision_layer_bit(6)
		
		for sprite in list_of_sprites:
			if sprite[1].get_collision_layer_bit(6):
				var position_to_consider = actual_position(sprite[1].global_position, player.global_position, sqrtFOV)
				sprite[2] = position_to_consider
				display_emerald(sprite)
				break
		return
	
	for sprite in list_of_sprites:
		if sprite[1].is_inside_tree() and distance_in_limits(sprite[1].global_position, player.global_position, sqrtFOV):
			var position_to_consider = actual_position(sprite[1].global_position, player.global_position, sqrtFOV)
			sprite[2] = position_to_consider
			sprite[0].texture = sprite[1].find_node("Sprite").texture
			sprite[0].frame = sprite[1].find_node("Sprite").frame
			sprite[0].visible = sprite[1].get_parent() != null
		elif not sprite[1].is_inside_tree():
			sprite[0].visible = false
	
	display_sprites(list_of_sprites)


func display_sprites(lst):
	for sprite in lst:
		var player_to_sprite = (sprite[2] - player.global_position).rotated(-player.rotation)
		var vector_dist = player_to_sprite.length_squared()
		
		var scale_factor = (-15.0/(6.5*CHECKER_SIZE*16.0)) * -player_to_sprite.y + 1
		sprite[0].scale = Vector2(scale_factor,scale_factor) if player_to_sprite.y < 0 else Vector2.ONE
		if vector_dist > pow(6.5*CHECKER_SIZE,2): sprite[0].scale = Vector2.ZERO
		
		sprite[0].position.y = vertical_distance_poly(-player_to_sprite)
		sprite[0].position.x = horizontal_distance_poly(-player_to_sprite)
		
		sprite[0].z_index = 240-(vector_dist)/(CHECKER_SIZE*CHECKER_SIZE) # z-index in [-4096, 4096]

func display_emerald(sprite):
	sprite[0].visible = true
	sprite[0].frame = sprite[1].find_node("Sprite").frame
	
	var player_to_sprite = (sprite[2] - player.global_position).rotated(-player.rotation)
	var vector_dist = player_to_sprite.length_squared()
		
	var scale_factor = (-15.0/(6.5*CHECKER_SIZE*16.0)) * -player_to_sprite.y + 1
	sprite[0].scale = Vector2(scale_factor,scale_factor) if player_to_sprite.y < 0 else Vector2.ONE
	if vector_dist > pow(6.5*CHECKER_SIZE,2): sprite[0].scale = Vector2.ZERO
		
	sprite[0].position.y = vertical_distance_poly(-player_to_sprite)
	sprite[0].position.x = horizontal_distance_poly(-player_to_sprite)


func vertical_distance_poly(pos):
	
	var x = abs(pos.x/192)
	var y = pos.y
	
	if x >= 4.5: return 300
	elif  y < -200: return 800
	
	if abs(x-4) < 0.01:
		return 0.0001695421*pow(y,2)-0.3924479167*y+388.45 + 39
	if abs(x-3) < 0.01:
		#?, 250?, 220, 183, 172, 160
		return 0.0001695421*pow(y,2)-0.3924479167*y+388.45
	if abs(x-2) < 0.01:
		#?, 350, 250, 190, 157, 147, 145
		if y < 100:
			return ((414.43-600)/100)*(y-100)+414.43
		return -0.0000002250*pow(y,3)+0.0007878595*pow(y,2)-0.9155850419*y+498.3333333333
	if abs(x-1) < 0.01:
		#530, 325, 220, 165, 137
		if y > 960:
			return 130
		if y > 400:
			return -sqrt(234000-pow((y-930)/1.95,2))+620 -7
		return -0.0000008595*pow(y,3)+0.0017729260*pow(y,2)-1.3663814484*y+529.6142857
	if abs(x) < 0.01:
		if y > 930:
			return 125
		if y < 0:
			return 520-1.5*y
		if y < 180:
			return ((316-520)/180)*(y-180)+316
		return max(125,-sqrt(250000-pow((y-930)/1.9,2))+623)
	
	return abs(x-floor(x))*vertical_distance_poly(Vector2(ceil(x)*192,y)) + (
		0) + abs(x-ceil(x))*vertical_distance_poly(Vector2(floor(x)*192,y))

func horizontal_distance_poly(pos):
	
	var x = abs(pos.x/192)
	var sign_of_x = -1 if pos.x < 0 else 1
	var y = pos.y
	
	if x >= 4.5: return -200.0 if sign_of_x >= 0 else 960+200.0
	
	var dist_from_left = 0
	
	if abs(x-5) < 0.01:
		return 800
	if abs(x-4) < 0.01:
		dist_from_left = -0.0001627604*pow(y,2)+0.55625*y-242.1 - 103
		return dist_from_left if pos.x > 0 else 960-dist_from_left
	if abs(x-3) < 0.01:
		#?, -30, 24, 90, 141, 183
		dist_from_left = -0.0001627604*pow(y,2)+0.55625*y-242.1
		return dist_from_left if pos.x > 0 else 960-dist_from_left
	if abs(x-2) < 0.01:
		#?, 28, 111, 172, 210, 248, 278
		if y <= 671:
			dist_from_left = 0.0000001818*pow(y,3)-0.0005395206*pow(y,2)+0.6977444334*y-87.3333333333
			return dist_from_left if pos.x > 0 else 960-dist_from_left
		if y <= 1104:
			dist_from_left = (0.0000001818*pow(y,3)-0.0007124535*pow(y,2)+1.1829936894*y-142.233333333) / 2.0
			return dist_from_left if pos.x > 0 else 960-dist_from_left
		dist_from_left = -0.0001729329*pow(y,2)+0.4852492560*y-54.9
		return dist_from_left if pos.x > 0 else 960-dist_from_left
	if abs(x-1) < 0.01:
		#180,246,291,321,348 ... 378
		dist_from_left = 0.0000000937*pow(y,3)-0.0002946031*pow(y,2)+0.3866378753*y+180.5838509317
		return dist_from_left if pos.x > 0 else 960-dist_from_left
	if abs(x) < 0.01:
		return 480
	
	return abs(x-floor(x))*horizontal_distance_poly(Vector2(sign_of_x*ceil(x)*192,y)) + (
		0) + abs(x-ceil(x))*horizontal_distance_poly(Vector2(sign_of_x*floor(x)*192,y))

#Unused
func sort_by_distance(lst):
	var new_lst = []
	
	while lst.size() > 0:
		var best_so_far = null
		for i in range(lst.size()):
			if best_so_far == null or best_so_far[1] < lst[i][2].distance_squared_to(player.position):
				best_so_far = [i, lst[i][2].distance_squared_to(player.global_position)]
		new_lst += [lst[best_so_far[0]]]
		lst.pop_at(best_so_far[0])
	
	return new_lst

func distance_in_limits(test, reference, limit):
	return (abs(test.x - reference.x) <= limit or abs(test.x - reference.x + BOARD_SIZE) <= limit or
		abs(test.x - reference.x - BOARD_SIZE) <= limit) and (
			abs(test.y - reference.y) <= limit or abs(test.y - reference.y + BOARD_SIZE) <= limit or
				abs(test.y - reference.y - BOARD_SIZE) <= limit
	)

func actual_position(test, reference, limit):
	var new_position = Vector2.ZERO
	if abs(test.x - reference.x) <= limit: new_position.x = test.x
	elif abs(test.x - reference.x + BOARD_SIZE) <= limit: new_position.x = test.x + BOARD_SIZE
	elif abs(test.x - reference.x - BOARD_SIZE) <= limit: new_position.x = test.x - BOARD_SIZE
	
	if abs(test.y - reference.y) <= limit: new_position.y = test.y
	elif abs(test.y - reference.y + BOARD_SIZE) <= limit: new_position.y = test.y + BOARD_SIZE
	elif abs(test.y - reference.y - BOARD_SIZE) <= limit: new_position.y = test.y - BOARD_SIZE
	
	return new_position

func make_sprite_list(initial):
	if initial:
		for child in self.get_children():
			self.remove_child(child)
			child.queue_free()
		list_of_sprites = []
		
		for child in get_parent().get_parent().get_children():
			if child is Area2D and (not child.has_method("is_active") or child.is_active() == true):
				var new_sprite = child.find_node("Sprite").duplicate()
				self.add_child(new_sprite)
				list_of_sprites += [[new_sprite, child, Vector2.ZERO]]
		return
	
	var i = 0
	while i < list_of_sprites.size():
		if list_of_sprites[i][1] == null or (
			list_of_sprites[i][1].has_method("is_active") and not list_of_sprites[i][1].is_active()) or (
				list_of_sprites[i][1].get_parent() == null
			):
			remove_child(list_of_sprites[i][0])
			list_of_sprites.pop_at(i)
		else:
			i += 1

# Unused
func add_new_sprites():
	for child1 in get_parent().get_parent().get_children():
		if child1 is Area2D and child1.get_collision_layer_bit(5):
			print(child1)
			var found = false
			for child2 in list_of_sprites:
				if child2[1] == child1:
					found = true
			if not found:
				var new_sprite = child1.find_node("Sprite").duplicate()
				add_child(new_sprite)
				list_of_sprites += [[new_sprite, child1, Vector2.ZERO]]

func add_new_sprite(object):
	var new_sprite = object.find_node("Sprite").duplicate()
	add_child(new_sprite)
	list_of_sprites += [[new_sprite, object, Vector2.ZERO]]
