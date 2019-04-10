extends Spatial



func _ready():
	pass

func set_gleam(count):
	if count == 0:
		$Mesh1.visible = false
		$Mesh2.visible = false
		$Mesh3.visible = false
	elif count == 1:
		$Mesh1.visible = true
		$Mesh2.visible = false
		$Mesh3.visible = false
	elif count == 2:
		$Mesh1.visible = true
		$Mesh2.visible = true
		$Mesh3.visible = false
	elif count == 3:
		$Mesh1.visible = true
		$Mesh2.visible = true
		$Mesh3.visible = true