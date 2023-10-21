extends KinematicBody2D


var velocity
var camera_dir
var turn_timer := 0
var turn_direction := true
var height := [0, false]
var increasing_velocity := false

var ring_count := 0

var game_speed = 1.0
var game_speed_list = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0]
var buffer_game_speedup := false

var quitting_animation := 0

var timer := 0

var MAX_VELOCITY = 12

var BOARD_SIZE
var CHECKER_SIZE

var GAME_PAUSED

var disable_game_speed := false

var win := false

var locked := false

# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = 0
	camera_dir = Vector2(0,-1)
	
	if get_parent():
		if get_parent().get("BOARD_SIZE"):
			BOARD_SIZE = get_parent().BOARD_SIZE
		if get_parent().get("CHECKER_SIZE"):
			CHECKER_SIZE = get_parent().CHECKER_SIZE
	
	$SFXPlayer.volume_db = -3


func _process(_delta):
	
	GAME_PAUSED = get_parent().GAME_PAUSED if (get_parent() and get_parent().get("GAME_PAUSED") != null) else GAME_PAUSED
	
	if GAME_PAUSED:
		if not Input.is_action_just_pressed("ui_accept"):
			$Sprite/AnimationPlayer.stop(false)
			return
		if get_parent() and get_parent().has_method("pause_game"):
			get_parent().pause_game(false)
		GAME_PAUSED = false
		return
	elif Input.is_action_just_pressed("ui_accept") and not locked:
		if get_parent() and get_parent().has_method("pause_game"):
			get_parent().pause_game(true)
		GAME_PAUSED = true
		return
	
	timer += 1
	if (timer % 1800 == 0 or buffer_game_speedup) and game_speed < game_speed_list[5] and not disable_game_speed:
		if height[0] > 0:
			buffer_game_speedup = true
		else:
			game_speed = game_speed_list[game_speed_list.find(game_speed) + 1]
			print(game_speed)
			buffer_game_speedup = false
	elif timer == 210 and velocity == 0:
		increasing_velocity = true
	
	teleport_to_centre()
	
	if quitting_animation:
		quitting_animation -= 1
		do_quit()
		if quitting_animation <= 0:
			if win:
				# warning-ignore:return_value_discarded
				get_tree().change_scene("res://src/levels/VictoryScreen.tscn")
			else:
				# warning-ignore:return_value_discarded
				get_tree().change_scene("res://src/levels/TitleScreen.tscn")
		return
	
	if velocity < -MAX_VELOCITY and height[0] <= 1:
		velocity = -MAX_VELOCITY
		increasing_velocity = false
	if velocity < MAX_VELOCITY:
		if Input.is_action_pressed("ui_up") and turn_timer <= 0 and not locked:
			increasing_velocity = true
		if increasing_velocity:
			velocity += 0.6 * game_speed if velocity != 0 else 6
	elif height[0] <= 1:
		velocity = MAX_VELOCITY
		increasing_velocity = false
	
	if height[0] <= 0:
		$Sprite/AnimationPlayer.play("Run")
		$Sprite/AnimationPlayer.playback_speed = abs(velocity/4.0 * game_speed)
		$Collision.disabled = false
		$Sprite.position = Vector2(1,-29)
		height[0] = 0
	else:
		$Sprite/AnimationPlayer.play("Jump")
		if height[1]:
			$Sprite.position.y = (300.0*game_speed*game_speed/441.0)*pow((height[0]-21.0/game_speed), 2) - 29.0 - 300
		else:
			$Sprite.position.y = (225.0*game_speed*game_speed/225.0)*pow((height[0]-15.0/game_speed), 2) - 29.0 - 225
		height[0] -= 1
		$Collision.disabled = true
	
	if Input.is_action_just_pressed("jump") and height[0] == 0 and not locked:
		# warning-ignore:integer_division
		height = [30 / game_speed, false]
		$SFXPlayer.stream = load("res://assets/sfx/S3K_jump.wav")
		$SFXPlayer.play()
		return
	
	if turn_timer > 0:
		do_turn()
		turn_timer -= 1
		return
	
	position += velocity*camera_dir*game_speed
	
	var dist_from_next_cross = get_cross_distance()
	
	if locked: return
	
	if Input.is_action_pressed("ui_left") and height[0] == 0 and (dist_from_next_cross <= 12*game_speed or velocity == 0):
		position = centre_position()
		# warning-ignore:integer_division
		turn_timer = int(-3 * game_speed + 18) + 2
		turn_direction = false
		return
	elif Input.is_action_pressed("ui_right") and height[0] == 0 and (dist_from_next_cross <= 12*game_speed or velocity == 0):
		position = centre_position()
		# warning-ignore:integer_division
		turn_timer = int(-3 * game_speed + 18) + 2
		turn_direction = true
		return

# Unused now
func find_checker_pos():
	var half_vector_size = Vector2(CHECKER_SIZE/2.0, CHECKER_SIZE/2.0)
	var to_return = Vector2(floor(($Collision.global_position.x - half_vector_size.x) / CHECKER_SIZE),
		floor(($Collision.global_position.y - half_vector_size.y) / CHECKER_SIZE))
	
	if to_return.x < 0:
		to_return.x += BOARD_SIZE/CHECKER_SIZE
	if to_return.y < 0:
		to_return.y += BOARD_SIZE/CHECKER_SIZE
	return to_return

func centre_position():
	var half_vector_size = Vector2(CHECKER_SIZE/2.0, CHECKER_SIZE/2.0)
	return ((position - half_vector_size)/CHECKER_SIZE).round()*CHECKER_SIZE + half_vector_size

func do_turn():
	var threshold = 2.0
	if turn_timer > threshold:
		var factor_sign = -1 if turn_direction else 1
		
		var frame = 20 - round(20*(turn_timer-2) / (-3*game_speed + 20))
		
		self.rotation = camera_dir.rotated(PI/2).angle() + factor_sign*(
			#(PI/2)/(30.0/game_speed - threshold) * (turn_timer - 30.0/game_speed)
			#(PI/(2*(-3*game_speed + 18 - threshold+1)))* (turn_timer+3*game_speed + 18 + threshold+1) + PI/2
			-(PI/2)*frame/20.0
		)
		return
	if turn_timer == threshold:
		self.rotation = round((self.rotation*2/PI))*(PI/2)
		camera_dir = nearest_right_angle_vector(Vector2.UP.rotated(self.rotation))
		return
	position += velocity*camera_dir

func start_quit(did_i_win):
	win = did_i_win
	if quitting_animation <= 0:
		quitting_animation = 90
		position = centre_position()

func do_quit():
	self.rotation += 3*PI/30.0
	$Sprite/AnimationPlayer.play("Run")
	
	get_parent().find_node("Transition").start_fadeout()

func reverse_velocity():
	velocity = -MAX_VELOCITY if velocity >= 0 else MAX_VELOCITY
	increasing_velocity = false

func teleport_to_centre():
	if position.x < -3264: position.x += BOARD_SIZE
	elif position.x > 2880: position.x -= BOARD_SIZE
	if position.y < -3264: position.y += BOARD_SIZE
	elif position.y > 2880: position.y -= BOARD_SIZE

func nearest_right_angle_vector(vector):
	if vector == Vector2.ZERO: return Vector2.UP
	
	var candidate_list = []
	if vector.distance_squared_to(Vector2.UP) < vector.distance_to(Vector2.DOWN):
		candidate_list += [Vector2.UP]
	else:
		candidate_list += [Vector2.DOWN]
	if vector.distance_squared_to(Vector2.LEFT) < vector.distance_to(Vector2.RIGHT):
		candidate_list += [Vector2.LEFT]
	else:
		candidate_list += [Vector2.RIGHT]
	if vector.distance_squared_to(candidate_list[0]) < vector.distance_squared_to(candidate_list[1]):
		return candidate_list[0]
	return candidate_list[1]

func start_spring_jump():
	velocity = 2.2*MAX_VELOCITY if velocity >= 0 else 5*-MAX_VELOCITY
	height = [44 / game_speed, true]
	turn_timer = 0
	self.rotation = camera_dir.angle() + PI/2

func get_cross_distance():
	if (camera_dir == Vector2.UP and velocity >= 0) or (camera_dir == Vector2.DOWN and velocity < 0):
		return self.position.y - floor((self.position.y - CHECKER_SIZE/2.0)/CHECKER_SIZE)*CHECKER_SIZE - CHECKER_SIZE/2.0
		
	elif (camera_dir == Vector2.DOWN and velocity >= 0) or (camera_dir == Vector2.UP and velocity < 0):
		return ceil((self.position.y - CHECKER_SIZE/2.0)/CHECKER_SIZE)*CHECKER_SIZE + CHECKER_SIZE/2.0 - self.position.y
		
	elif (camera_dir == Vector2.LEFT and velocity >= 0) or (camera_dir == Vector2.RIGHT and velocity < 0):
		return self.position.x - floor((self.position.x - CHECKER_SIZE/2.0)/CHECKER_SIZE)*CHECKER_SIZE - CHECKER_SIZE/2.0
		
	elif (camera_dir == Vector2.RIGHT and velocity >= 0) or (camera_dir == Vector2.LEFT and velocity < 0):
		return ceil((self.position.x - CHECKER_SIZE/2.0)/CHECKER_SIZE)*CHECKER_SIZE + CHECKER_SIZE/2.0 - self.position.x
	return CHECKER_SIZE

func get_turn_timer():
	return [turn_timer, game_speed, velocity, turn_direction, camera_dir]

func parity_of_position():
	var half_checker = CHECKER_SIZE/2.0
	
	var to_add = 1 if get_cross_distance() == 0 else 0
	
	var checker_position_rounded = Vector2(floor((position.x - half_checker + to_add) / CHECKER_SIZE),
		floor((position.y - half_checker + to_add) / CHECKER_SIZE) )
	
	var parity_value = mod_wrap(int(checker_position_rounded.x), 2) != mod_wrap(int(checker_position_rounded.y), 2)
	if get_cross_distance() == 0:
		if camera_dir == Vector2.LEFT or camera_dir == Vector2.UP:
			parity_value = not parity_value
	
	if camera_dir == Vector2.UP or camera_dir == Vector2.RIGHT:
		return parity_value
	return  not parity_value

func mod_wrap(x, n):
	if x < 0:
		return mod_wrap(x+n, n)
	return x % 2

func get_height():
	if height[0] == 0:
		return -29.0
	if height[1]:
		return (300.0*game_speed*game_speed/484.0)*pow((height[0]-22.0/game_speed), 2) - 29.0 - 300
	else:
		#return (225.0*game_speed*game_speed/225.0)*pow((height[0]-15.0/game_speed), 2) - 29.0 - 225
		return (180.0*game_speed*game_speed/225.0)*pow((height[0]-15.0/game_speed), 2) - 29.0 - 180

func get_quitting_animation():
	return quitting_animation

func set_camera_dir(rot):
	if abs(rot - PI/2) < 0.1:
		camera_dir = Vector2.RIGHT
	elif abs(rot) < 0.1:
		camera_dir = Vector2.UP
	elif abs(rot - 3*PI/2) < 0.1:
		camera_dir = Vector2.LEFT
	elif abs(rot + PI) < 0.1:
		camera_dir = Vector2.DOWN

func set_game_speed(value, lock):
	if lock:
		disable_game_speed = true
	velocity = MAX_VELOCITY
	game_speed = value

func lock_controls(value):
	locked = value
