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
