extends Spatial

var myRoot

func _ready():
	myRoot = get_parent()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func button_execute(name):
	if name == "Retry":
		get_tree().reload_current_scene()
	elif name == "Test":
		print("test")
	else:
		print("Unknown name: " + name)