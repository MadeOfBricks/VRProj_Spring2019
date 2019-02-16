extends KinematicBody

const GRAVITY = -24.8
const MAX_SPEED = 20
const JUMP_SPEED = 14
const ACCEL = 4.5
const DEACCEL = 12
const MAX_SLOPE_ANGLE = 40
const NON_USE_VECTOR = Vector3(-999,-999,-999)

var rightController
var leftController
var sounds
var dir = Vector3()
var vel = Vector3()

#var airJumps = 1

var vRConButtons = {"FarButton":1,"NearButton":7,"StickPress":15,"Grip":2,"Trigger":15}
var vRConAxis = {"StickX":0,"StickY":1,"Trigger":2}

var leftStick = Vector2()
var rightStick = Vector2()
var sticks = [leftStick,rightStick]
var stickTurnReady = [true,true]

var tugVec = [NON_USE_VECTOR,NON_USE_VECTOR,NON_USE_VECTOR,NON_USE_VECTOR]

func _ready():
	rightController = $ARVROrigin/OVRControllerRight
	leftController = $ARVROrigin/OVRControllerLeft
	sounds = $Sounds

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)

func process_input(delta):
	var dBTimer = get_parent().get_node("DebugTimer")
	
	#-------------------------------
	#Stick variables and array
	var leftAxes = leftController.joystick_axes()
	var rightAxes = rightController.joystick_axes()
	
	leftStick = Vector2(leftAxes[0],leftAxes[1])
	rightStick = Vector2(rightAxes[0],rightAxes[1])
	sticks[0] = leftStick
	sticks[1] = rightStick
	#-------------------------------
	
	#-------------------------------
	#Stick turning
	for i in range(0,2):
		var stick = sticks[i]
		var stickX = sticks[i].x
		if abs(stickX) > .9:
			if stickTurnReady[i]:
				rotate_y(deg2rad(45) * sign(stickX) * -1)
				stickTurnReady[i] = false
		else:
			stickTurnReady[i] = true
	#-------------------------------
	
	
	#-------------------------------
	#Tug dash
	var tugging = false
	for i in [0,2]:
		var thisCon
		if i == 0: thisCon = leftController
		elif i == 2: thisCon = rightController
		if tugVec[i] != NON_USE_VECTOR:
			tugging = true
			tugVec[i+1] = thisCon.translation
			
			#Debug Text
			var dBString = "Start: " + String(tugVec[i]) + "\nEnd: " + String(tugVec[i+1]) + "\nIndeces: " \
			+ String(i) + "," + String(i+1)
			dBTimer.myText = dBString
	
	if tugging == false:
		dBTimer.myText = ""
	#-------------------------------
	
	
	#------------------------------
	#Debug Printing(UNIMP)
	if false:
		var dBString = "Left: "
		for i in range (0,4):
			dBString += String(leftAxes[i]) + " "
	#------------------------------
	

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
	var delta = get_physics_process_delta_time()
	#print("Left click " + String(button))
	VR_con_pressed(leftController,button,delta)



func _on_OVRControllerRight_button_pressed(button):
	var delta = get_physics_process_delta_time()
	#print("Right click " + String(button))
	VR_con_pressed(rightController,button,delta)



func _on_OVRControllerLeft_button_release(button):
	var delta = get_physics_process_delta_time()
	#print("Right click " + String(button))
	VR_con_released(leftController,button,delta)


func _on_OVRControllerRight_button_release(button):
	var delta = get_physics_process_delta_time()
	#print("Right click " + String(button))
	VR_con_released(rightController,button,delta)

func VR_con_pressed(controller,button,delta):
	if button == vRConButtons["Trigger"]:
		var tugIndex
		if controller == leftController:
			tugIndex = 0
		if controller == rightController:
			tugIndex = 2
		
		tugVec[tugIndex] = controller.translation
		

func VR_con_released(controller,button,delta):
	if button == vRConButtons["Trigger"]:
		var dashVec = Vector3()
		var index
		if controller == leftController:
			index = 0
		elif controller == rightController:
			index = 2
		
		dashVec = tugVec[index + 1] - tugVec[index]
		print("dashVec: " + String(dashVec))
		
		tug_dash(dashVec,delta)
		
		tugVec[index] = NON_USE_VECTOR
		tugVec[index+1] = NON_USE_VECTOR

func tug_dash(dashVec,delta):
	var vec = dashVec.normalized()
	var magnitude = clamp(dashVec.length() * 30,0,200)
	vec *= magnitude * -1
	vec = vec.rotated(Vector3(0,1,0),rotation.y)
	
	
	vel += vec

#OLD MOVEMENT
func player_hop(controller,delta):
	var dashVector = controller.global_transform.basis.z.normalized()
	vel = dashVector * -700 * delta
	sounds.play("Hop")
	