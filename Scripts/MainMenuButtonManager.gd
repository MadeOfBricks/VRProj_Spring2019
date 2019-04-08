extends Spatial

var root

func _ready():
	root = get_tree().get_root().get_child(0)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func button_execute(name):
	if name == "StartGame":
		get_tree().change_scene("res://Level.tscn")
	elif name == "Playground":
		get_tree().change_scene("res://Playground.tscn")
	elif name == "Test":
		print("test")
	else:
		print("Unknown name: " + name)