extends StaticBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	var rands = Vector3(rand_range(0,360),rand_range(0,360),rand_range(0,360))
	rotation_degrees = rands

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
