extends StaticBody

var root
var sounds
var player

var health = 2

func _ready():
	sounds = $Sounds
	root = get_tree().get_root()
	player = root.get_node("Player")

func _physics_process(delta):
	pass#rotate(Vector3(0,1,0),.05)

func state_change(state):
	pass

func sword_hit():
	#TODO: Replace with state_change("flinch")
	health-= 1
	sounds.play("Die")
	if health <= 0:
		destroy()

func destroy():
	$CollisionShape.disabled = true
	$Meshes.visible = false
	$RemoveTimer.start()

func _on_RemoveTimer_timeout():
	queue_free()
