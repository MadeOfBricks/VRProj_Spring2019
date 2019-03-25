extends Spatial

var enemy

func _ready():
	$AnimationPlayer.play("Spin")
	set_process(true)
	if enemy == null:
		enemy = get_parent()

func _process(delta):
	if enemy != null:
		global_transform.origin = enemy.get_node("MarkerPoint").global_transform.origin

func use_mesh(mesh):
	var allMeshes = $Meshes.get_children()
	if mesh == "purple":
		if $Meshes/PurpleMesh.visible == false:
			for thisMesh in allMeshes:
				thisMesh.visible = false
			$Meshes/PurpleMesh.visible = true
	elif mesh == "yellow":
		if $Meshes/YellowMesh.visible == false:
			for thisMesh in allMeshes:
				thisMesh.visible = false
			$Meshes/YellowMesh.visible = true
		