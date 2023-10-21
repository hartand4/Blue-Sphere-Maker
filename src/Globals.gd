extends Node

var loaded_level_data = {}

export var perfect := false

export var current_level_number := 0

func _ready():
	pass


func _process(_delta):
	pass

func save_level(data, level_number):
	var path = './save/data.json'
	
	var current_data = load_data()
	if not current_data:
		current_data = {}
	
	current_data["level" + str(level_number)] = data
	
	var file = File.new()
	var dir = Directory.new()
	if not dir.file_exists('./save'):
		dir.open('./')
		dir.make_dir('save')
	file.open(path, File.WRITE)
	file.store_line(to_json(current_data))
	file.close()

func load_data():
	var path = './save/data.json'
	var file = File.new()
	if not file.file_exists(path):
		print('Nope')
		return
	file.open(path, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	return data

func load_level(level_number):
	var data = load_data()
	if data == null:
		loaded_level_data = null
		return
	if ("level" + str(level_number)) in data:
		loaded_level_data = data["level" + str(level_number)]
	else:
		loaded_level_data = null
