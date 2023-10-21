extends Node2D

var cursor_position = [0,0]

var transition := 0

var data = {}

func _ready():
	$BackgroundMusic.play()
	
	data = Globals.load_data()
	
	for i in range(16):
		var stage_label = $Levels.find_node("Stage%s" % (i+1))
		var number_label = $Levels.find_node("StageNumber%s" % (i+1))
		if data == null or not (('level%s' % i) in data):
			stage_label.texture = load("res://assets/background/menu/Empty.png")
			number_label.visible = false
	
	cursor_position = [0 if Globals.current_level_number < 8 else 2,
		Globals.current_level_number if Globals.current_level_number < 8 else Globals.current_level_number - 8]

func _process(_delta):
	if $BackgroundMusic.get_playback_position() > 12:
		$BackgroundMusic.seek($BackgroundMusic.get_playback_position() - 9.75)
	
	
	$Cursor/AnimationPlayer.play("Spin")
	$Cursor2.frame = $Cursor.frame
	
	$Cursor.position.x = [42, 276, 521, 755][cursor_position[0]]
	$Cursor.position.y = cursor_position[1]*48 + 306
	$Cursor2.position.y = $Cursor.position.y
	$Cursor2.position.x = $Cursor.position.x + (228 if cursor_position[0] % 2 == 0 else 169)
	
	if cursor_position[0] % 2 == 1:
		$Cursor.texture = load("res://assets/background/menu/CursorBallRed.png")
		$Cursor2.texture = load("res://assets/background/menu/CursorBallRed.png")
	else:
		$Cursor.texture = load("res://assets/background/menu/CursorBall.png")
		$Cursor2.texture = load("res://assets/background/menu/CursorBall.png")
	
	if transition > 0:
		transition -= 1
		if transition <= 0:
			if cursor_position[0] % 2 == 0:
				# warning-ignore:return_value_discarded
				get_tree().change_scene("res://src/levels/TestLevel.tscn")
			else:
				# warning-ignore:return_value_discarded
				get_tree().change_scene("res://src/levels/LevelCreator.tscn")
		return
	
	if Input.is_action_just_pressed("jump"):
		handle_scene_change()
		return
	
	if Input.is_action_just_pressed("ui_left"):
		cursor_position[0] -= 1
		if cursor_position[0] < 0: cursor_position[0] += 4
	elif Input.is_action_just_pressed("ui_right"):
		cursor_position[0] += 1
		if cursor_position[0] > 3: cursor_position[0] = cursor_position[0]-4
	
	if Input.is_action_just_pressed("ui_up"):
		cursor_position[1] -= 1
		if cursor_position[1] < 0: cursor_position[1] += 8
	elif Input.is_action_just_pressed("ui_down"):
		cursor_position[1] += 1
		if cursor_position[1] >= 8: cursor_position[1] -= 8

func handle_scene_change():
	var trying_to_load = cursor_position[1] + (8 if cursor_position[0] >= 2 else 0)
	if cursor_position[0] % 2 == 0:
		if data == null or not (('level%s' % trying_to_load) in data):
			return
		else:
			Globals.current_level_number = trying_to_load
			transition = 80
			$SFX.play()
			$Transition.start_fast_fadeout()
	else:
		Globals.current_level_number = trying_to_load
		transition = 80
		$SFX.play()
		$Transition.start_fast_fadeout()
