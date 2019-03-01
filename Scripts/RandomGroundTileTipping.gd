extends Spatial

var tiles

func _ready():
	tiles = get_children()
	
	for tile in tiles:
		var randX = rand_range(-2,2)
		var randY = rand_range(-2,2)
		tile.rotation_degrees = Vector3(randX,0,randY)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
