extends CanvasLayer


var timer := -90
var fast := false


# Called when the node enters the scene tree for the first time.
func _ready():
	$White.color.a = 1


func _process(_delta):
	if timer > 0:
		$White.color.a += 0.05 if fast else 0.02
		$White.color.a = min(1, $White.color.a)
	elif timer < 0:
		$White.color.a -= 0.05
		$White.color.a = max(0, $White.color.a)
	
func start_fadeout():
	timer = 300

func start_fast_fadeout():
	timer = 300
	fast = true
