extends Node2D

var cursor_location := Vector2.ZERO

var level_list := []

var ring_count := 0
var blue_count := 0

var initial_setup := true

func _ready():
	for i in range(32):
		level_list += [[]]
		for _j in range(32):
			level_list[i] += [0]
	
	Globals.load_level(Globals.current_level_number)
	$Sidebar/LevelNumber.frame = Globals.current_level_number
	
	$PlayerError.visible = false
	$BlueError.visible = false
	
	if Globals.loaded_level_data:
		setup_level(Globals.loaded_level_data)
	else:
		$Background.texture = load("res://assets/background/floors/LevelCreateFloor1.png")
	
	$BackgroundMusic.play()


func _process(_delta):
	
	if $BackgroundMusic.get_playback_position() > 38:
		$BackgroundMusic.seek($BackgroundMusic.get_playback_position() - 36.02)
	
	$Cursor/AnimationPlayer.play("Flash")
	
	if cursor_location.x < 32:
		process_cursor_movement()
	else:
		process_sidebar_movement()
		
	$Cursor.position = Vector2(22*cursor_location.x + 11, 22*cursor_location.y + 19)
	if 0 <= cursor_location.y and cursor_location.y <= 4:
		$SideCursor.position.y = [38, 182, 460, 608, 668][int(cursor_location.y)]
	
	$Cursor.visible = true if cursor_location.x < 32 else false
	$SideCursor.visible = false if cursor_location.x < 32 else true


func process_cursor_movement():
	if Input.is_action_just_pressed("jump"):
		for child in self.get_children():
			if child != $Cursor and child.get("position") != null and child.position == $Cursor.position:
				child.frame = child.frame + 1 if child.frame < 9 else 0
				level_list[int(cursor_location.y)][int(cursor_location.x)] = child.frame + 1
				update_counters()
				return
		
		var new_obj = load("res://src/scenes/CreatorObject.tscn").instance()
		self.add_child(new_obj)
		new_obj.position = $Cursor.position
		new_obj.frame = 0
		level_list[int(cursor_location.y)][int(cursor_location.x)] = 1
		update_counters()
		return
		
	if Input.is_action_just_pressed("ui_cancel"):
		for child in self.get_children():
			if child != $Cursor and child.get("position") != null and child.position == $Cursor.position:
				self.remove_child(child)
				level_list[int(cursor_location.y)][int(cursor_location.x)] = 0
		update_counters()
		return
	
	if Input.is_action_just_pressed("aux"):
		for child in self.get_children():
			if child != $Cursor and child.get("position") != null and child.position == $Cursor.position and (
			child.frame in [0,1,2,3,6,7,8,9]):
				child.frame = child.frame + 6 if child.frame < 4 else child.frame - 6
				level_list[int(cursor_location.y)][int(cursor_location.x)] = child.frame + 1
				update_counters()
				return
		return
	
	if Input.is_action_just_pressed("ui_left"):
		cursor_location.x -= 1
		if cursor_location.x < 0:
			cursor_location = Vector2(32, 0)
	elif Input.is_action_just_pressed("ui_right"):
		cursor_location.x += 1
		if cursor_location.x >= 32:
			cursor_location = Vector2(32, 0)
	if cursor_location.x >= 32: return
	
	if Input.is_action_just_pressed("ui_up"):
		cursor_location.y -= 1
		if cursor_location.y < 0:
			cursor_location.y = 31
	elif Input.is_action_just_pressed("ui_down"):
		cursor_location.y += 1
		if cursor_location.y >= 32:
			cursor_location.y = 0

func process_sidebar_movement():
	if Input.is_action_just_pressed("ui_left"):
		cursor_location = Vector2(31, 0)
		return
	elif Input.is_action_just_pressed("ui_right"):
		cursor_location = Vector2.ZERO
		return
	
	if Input.is_action_just_pressed("ui_down"):
		cursor_location.y = cursor_location.y + 1 if cursor_location.y < 4 else 0.0
		return
	elif Input.is_action_just_pressed("ui_up"):
		cursor_location.y = cursor_location.y - 1 if cursor_location.y > 0 else 4.0
		return
	
	if Input.is_action_just_pressed("jump"):
		if cursor_location.y == 0:
			$Sidebar/Palette.frame = $Sidebar/Palette.frame + 1 if $Sidebar/Palette.frame < 9 else 0
			$Background.texture = load("res://assets/background/floors/LevelCreateFloor%s.png" % ($Sidebar/Palette.frame + 1))
		elif cursor_location.y == 1:
			$Sidebar/Arrow.rotation_degrees = $Sidebar/Arrow.rotation_degrees + 90 if $Sidebar/Arrow.rotation_degrees < 360 else 0
		
		elif cursor_location.y == 2:
			$Sidebar/LevelNumber.frame = $Sidebar/LevelNumber.frame + 1 if $Sidebar/LevelNumber.frame < 9 else 0
		elif cursor_location.y == 3:
			save_level_to_file()
		elif cursor_location.y == 4:
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/TitleScreen.tscn")

func update_counters():
	ring_count = 0
	blue_count = 0
	for child in get_children():
		if "CreatorObject" in child.name:
			if child.frame == 0 or child.frame == 6:
				blue_count += 1
			if child.frame in [4,6,7]:
				ring_count += 1
	$Sidebar/Hundreds.frame = int(ring_count / 100.0)
	$Sidebar/Tens.frame = int((ring_count % 100) / 10.0)
	$Sidebar/Units.frame = ring_count % 10
	
	$Sidebar/HundredsB.frame = int(blue_count / 100.0)
	$Sidebar/TensB.frame = int((blue_count % 100) / 10.0)
	$Sidebar/UnitsB.frame = blue_count % 10

func save_level_to_file():
	$PlayerError.visible = false
	$BlueError.visible = false
	
	var found_player = false
	var found_blue = false
	for row in level_list:
		for col in row:
			if col == 6:
				if found_player:
					$PlayerError.visible = true
					return
				found_player = true
			elif col == 1:
				found_blue = true
	if not (found_player and found_blue):
		$PlayerError.visible = not found_player
		$BlueError.visible = not found_blue
		return
	
	$SFX.play()
	
	var data = {}
	data["rings"] = $Sidebar/Hundreds.frame*100 + $Sidebar/Tens.frame*10 + $Sidebar/Units.frame
	data["palette"] = $Sidebar/Palette.frame
	data["level"] = []
	data["rotation"] = $Sidebar/Arrow.rotation_degrees
	
	for row in level_list:
		var row_str = ''
		for col in row:
			row_str += ['N','B','R','S','Y','G','P','b','r','s','y'][col]
		data["level"] += [row_str]
	
	Globals.save_level(data, $Sidebar/LevelNumber.frame)
	print('save successful')

func setup_level(data):
	$Sidebar/Palette.frame = data['palette']
	$Background.texture = load("res://assets/background/floors/LevelCreateFloor%s.png" % ($Sidebar/Palette.frame + 1))
	$Sidebar/Arrow.rotation_degrees = data['rotation']
	
	for i in range(data['level'].size()):
		for j in range(data['level'][i].length()):
			var char_to_check = data['level'][i][j]
			var position_for_here = Vector2(22*j + 11, 22*i + 19)
			
			if char_to_check != 'N':
				var new_obj = load("res://src/scenes/CreatorObject.tscn").instance()
				self.add_child(new_obj)
				new_obj.position = position_for_here
				
				if char_to_check == 'B':
					new_obj.frame = 0
				if char_to_check == 'R':
					new_obj.frame = 1
				if char_to_check == 'S':
					new_obj.frame = 2
				if char_to_check == 'Y':
					new_obj.frame = 3
				if char_to_check == 'G':
					new_obj.frame = 4
				if char_to_check == 'P':
					new_obj.frame = 5
				if char_to_check == 'b':
					new_obj.frame = 6
				if char_to_check == 'r':
					new_obj.frame = 7
				if char_to_check == 's':
					new_obj.frame = 8
				if char_to_check == 'y':
					new_obj.frame = 9
				
				level_list[i][j] = new_obj.frame + 1
	update_counters()
