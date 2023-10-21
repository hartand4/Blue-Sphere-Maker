extends CanvasLayer

var sphere_count := 0
var ring_count := 0

var timer := 0
var perfect_timer := 0

var did_perfect := false

onready var player

func _ready():
	self.visible = true
	if get_parent() and get_parent().find_node("Player"):
		player = get_parent().find_node("Player")

func _process(_delta):
	
	if player == null or get_parent() == null: return
	if get_parent().GAME_PAUSED: return
	
	timer += 1
	if timer > 210 and timer < 530:
		$GetBlueSpheresText.rect_position.x -= 48
		$GetBlueSpheresText2.rect_position.x += 48
	
	sphere_count = get_parent().global_blue_count
	# warning-ignore:narrowing_conversion
	ring_count = max(get_parent().max_rings - player.ring_count, 0)
	
	# Count up blues
	# warning-ignore:integer_division
	$SphereCounter/Hundreds.frame = sphere_count / 100
	# warning-ignore:integer_division
	$SphereCounter/Tens.frame = (sphere_count % 100) / 10
	$SphereCounter/Units.frame = sphere_count % 10
	
	# Count up rings
	# warning-ignore:integer_division
	$RingCounter/Hundreds.frame = ring_count / 100
	# warning-ignore:integer_division
	$RingCounter/Tens.frame = (ring_count % 100) / 10
	$RingCounter/Units.frame = ring_count % 10
	
	if perfect_timer:
		perfect_timer -= 1
		if perfect_timer >= 230:
			$PerfectText.rect_position.x += 48
			$PerfectText2.rect_position.x -= 48
		elif perfect_timer <= 10:
			$PerfectText.rect_position.x -= 48
			$PerfectText2.rect_position.x += 48
		if perfect_timer <= 0:
			did_perfect = true
	elif ring_count == 0 and not did_perfect:
		Globals.perfect = true
		perfect_timer = 240
		get_parent().find_node("MakeSFX").stream = load("res://assets/sfx/S3K_perfect.wav")
		get_parent().find_node("MakeSFX").play()
