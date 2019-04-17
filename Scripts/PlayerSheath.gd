extends Spatial

const SHEATH_FROM_HEAD_DIST = .4


var headset


func _ready():
	headset = get_parent().get_node("ARVRCamera")

func _physics_process(delta):
	var headsetBackVec = headset.global_transform.basis.z
	translation = headset.translation + headsetBackVec.normalized() * SHEATH_FROM_HEAD_DIST
	translation.y = headset.translation.y
	#rotation_degrees = headset.rotation_degrees
