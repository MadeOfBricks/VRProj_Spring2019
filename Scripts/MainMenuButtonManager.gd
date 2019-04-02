extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

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