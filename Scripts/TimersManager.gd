extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func reset_all():
	for timer in get_children():
		timer.stop()
		timer.set_wait_time(timer.get_wait_time())
