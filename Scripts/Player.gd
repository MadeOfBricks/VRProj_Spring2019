extends KinematicBody

const GRAVITY = -24.8
const MAX_SPEED = 20
const JUMP_SPEED = 14
const ACCEL = 4.5
const DEACCEL = 16
const MAX_SLOPE_ANGLE = 40

var rightController
var leftController
var dir = Vector3()
var vel = Vector3()

var vRConButtons = {"FarButton":1,"NearButton":7,"StickPress":15,"Grip":2,"Trigger":15}

func _ready():
	rightController = $ARVROrigin/OVRControllerRight
	leftController = $ARVROrigin/OVRControllerLeft

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)

func process_input(delta):
	pass

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
	vel.y += delta*GRAVITY
	
	var hvel = vel
	hvel.y = 0
	
	var target = dir
	target *= MAX_SPEED
	
	var accel
	if dir.dot(hvel)<0:
		accel = ACCEL
	elif is_on_floor():
		accel = DEACCEL
	else:
		accel = 0
	
	hvel = hvel.linear_interpolate(target, accel*delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel,Vector3(0,1,0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))



func _on_OVRControllerLeft_button_pressed(button):
	print("Left click " + String(button))



func _on_OVRControllerRight_button_pressed(button):
	var delta = get_physics_process_delta_time()
	print("Right click " + String(button))
	if button == vRConButtons["Trigger"]:
		var dashVector = rightController.global_transform.basis.z.normalized()
		vel = dashVector * -700 * delta
	
	
