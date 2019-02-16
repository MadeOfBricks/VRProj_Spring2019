extends Spatial

var coobCount = get_child_count()

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass




func _on_Coob_tree_exited():coobCount -= 1


func _on_Coob2_tree_exited():coobCount -= 1


func _on_Coob3_tree_exited():coobCount -= 1


func _on_Coob4_tree_exited():coobCount -= 1


func _on_Coob5_tree_exited():coobCount -= 1


func _on_Coob6_tree_exited():coobCount -= 1
