extends StaticBody

var sounds

func _ready():
	sounds = $EntitySounds

func sword_hit():
	sounds.play("Die")
	destroy()

func destroy():
	$CollisionShape.disabled = true
	$Mesh.visible = false
	$RemoveTimer.start()

func _on_RemoveTimer_timeout():
	queue_free()
