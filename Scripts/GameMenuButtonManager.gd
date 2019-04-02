extends Spatial

var myRoot

func _ready():
	myRoot = get_parent()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func button_execute(name):
	if name == "MainMenu":
		get_tree().change_scene("res://MainMenuScene.tscn")
	elif name == "Continue":
		myRoot.get_parent().game_menu_removed()
		myRoot.queue_free()
	elif name == "Test":
		print("test")
	else:
		print("Unknown name: " + name)