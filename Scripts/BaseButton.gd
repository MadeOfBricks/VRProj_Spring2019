extends Spatial

var manager

func _ready():
	manager = get_parent()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Area_area_entered(area):
	if area.name == "MenuPresser":
		print("MenuPresser detected")
		manager.button_execute(name)
		
