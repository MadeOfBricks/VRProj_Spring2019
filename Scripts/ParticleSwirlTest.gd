extends Particles

var moveDir = 1

const SCOOT_SPEED = 30

func _ready():
	set_process(true)

func _process(delta):
	translation.z += SCOOT_SPEED * moveDir * delta


func _on_Timer_timeout():
	moveDir *= -1
