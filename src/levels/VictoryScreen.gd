extends Node2D

var timer := 0

var transition_timer := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$BackgroundMusic.stream = load("res://assets/sfx/S3K_clear.mp3")
	$BackgroundMusic.play()
	$Perfect.visible = false


func _process(_delta):
	timer += 1
	$Sprite/AnimationPlayer.play("Wag Finger")
	
	for i in range(7):
		var emerald = find_node("Emerald%s" % (i+1))
		emerald.position = Vector2(480, 360) + Vector2(
			180*sin(2*PI*(timer - i*250/7.0) / 250),
			-180*cos(2*PI*(timer - i*250/7.0) / 250)
		) + Vector2(0, 50*sin(2*PI*timer/180.0)).rotated(2*PI*(timer - i*250/7.0) / 250)
	
	if timer > 300:
		if (Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept")) and transition_timer == 0:
			transition_timer = 30
			$Transition.start_fast_fadeout()
		
		if Globals.perfect:
			$Perfect.visible = (timer % 30) < 15
			if timer == 301:
				$BackgroundMusic.stream = load("res://assets/sfx/S3K_continue.wav")
				$BackgroundMusic.play()
	
	if transition_timer > 0:
		transition_timer -= 1
		if transition_timer == 1:
			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://src/levels/TitleScreen.tscn")
