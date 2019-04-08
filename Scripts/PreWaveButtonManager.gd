extends Spatial

var root
signal waveStart

func _ready():
	root = get_tree().get_root().get_child(0)


func button_execute(name):
	if name == "Begin":
		get_parent().get_parent().get_parent().wave_start()
		queue_free()
	elif name == "MainMenu":
		get_tree().change_scene("res://MainMenuScene.tscn")
	else:
		print("Unknown name: " + name)