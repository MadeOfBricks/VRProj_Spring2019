extends KinematicBody
var dBTimer

const GRAVITY = -24.8
const MAX_SPEED = 20
const JUMP_SPEED = 14
const AIR_DASH_SPEED = 20
const ACCEL = 4.5
const GROUND_DEACCEL = 12
const WEAVE_DEACCEL = 4
const MAX_SLOPE_ANGLE = 40
const NON_USE_VECTOR = Vector3(-999,-999,-999)

var moveState = "stand"

var headset
var rightController
var leftController
var sounds
var enemies
var lastLockedEnemy
var dir = Vector3()
var vel = Vector3()

#var airJumps = 1
var vRGearPosLog = {"Head":[],"Right":[],"Left":[]}

var vRConButtons = {"FarButton":1,"NearButton":7,"StickPress":15,"Grip":2,"Trigger":15}
var vRConAxis = {"StickX":0,"StickY":1,"Trigger":2}

var leftStick = Vector2()
var rightStick = Vector2()
var sticks = [leftStick,rightStick]
var stickTurnReady = [true,true]

var tugVec = [NON_USE_VECTOR,NON_USE_VECTOR,NON_USE_VECTOR,NON_USE_VECTOR]
var weaveType = {"Left":1,"Right":2}
var weaving = false
var weaveSide = 0

func _ready():
	dBTimer = get_parent().get_node("DebugTimer")
	
	headset = $ARVROrigin/ARVRCamera
	rightController = $ARVROrigin/OVRControllerRight
	leftController = $ARVROrigin/OVRControllerLeft
	
	vRGearPosLog.Head.push_front($ARVROrigin/ARVRCamera.translation)
	vRGearPosLog.Right.push_front($ARVROrigin/OVRControllerRight.translation)
	
	
	sounds = $Sounds
	enemies = get_parent().get_node("Enemies")



func _physics_process(delta):
	process_positions(delta)
	process_input(delta)
	process_movement(delta)
	#process_post_movement(delta)

func process_positions(delta):
	#var dBString = ""
	vRGearPosLog.Head.push_front($ARVROrigin/ARVRCamera.transform.origin)
	vRGearPosLog.Right.push_front($ARVROrigin/OVRControllerRight.transform.origin)
	vRGearPosLog.Left.push_front($ARVROrigin/OVRControllerLeft.transform.origin)
	
	for gearPos in [vRGearPosLog.Head,vRGearPosLog.Right,vRGearPosLog.Left]:
		#dBString += String(gearPos[0]) + "\n"
		if gearPos.size()>5:
			gearPos.pop_back()
	
	#dBTimer.myText = dBString

func process_input(delta):
	
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
	#Weave-dashing
	if weaving:
		var headLog = vRGearPosLog.Head
		var headMovVec = headLog[1] - headLog[0]
		
		var rightVec = $ARVROrigin/ARVRCamera/WeaveRightTarget.translation \
		- translation
		
		var leftVec = $ARVROrigin/ARVRCamera/WeaveLeftTarget.translation \
		- translation
		
		
		var tarVec
		if weaveSide == weaveType.Left:
			tarVec = rightVec
		elif weaveSide == weaveType.Right:
			tarVec = leftVec
		
		
		if abs(headMovVec.length()) > .025:
			print( "Head doing: " + String(headMovVec))
			print("Needs to do: " + String(tarVec))
			print("Angular difference of " + String(rad2deg(headMovVec.angle_to(tarVec))))
			if rad2deg(headMovVec.angle_to(tarVec)) < 45:
				print("gud")
				weave_dash(headMovVec,delta)
			
	#-------------------------------
	
	#-------------------------------
	#Two-handed gust dash
	var gustPushing = true
	var leftVec
	var rightVec
	for i in [0,2]:
		var thisCon
		if i == 0: thisCon = leftController
		elif i == 2: thisCon = rightController
		
		if tugVec[i] != NON_USE_VECTOR:
			tugVec[i+1] = thisCon.translation
			
			if i == 0: 
				leftVec = tugVec[i+1] - tugVec[i]
			elif i == 2: 
				rightVec = tugVec[i+1] - tugVec[i]
		else:
			gustPushing = false
		
		
	
	if gustPushing:
		if leftVec.angle_to(rightVec) < 45:
			var avgVec = (leftVec + rightVec)/2
			
			if avgVec.length() > .4:
				gust_dash(avgVec,delta)
				
				for i in range(0,4):
					tugVec[i] = NON_USE_VECTOR
				
	#-------------------------------
	
	#-------------------------------
	#Tug dash (UNIMP)
	if false:
		var tugging = false
		for i in [0,2]:
			var thisCon
			if i == 0: thisCon = leftController
			elif i == 2: thisCon = rightController
			if tugVec[i] != NON_USE_VECTOR:
				
				tugging = true
				tugVec[i+1] = thisCon.translation#thisCon.global_transform.origin#thisCon.translation
				
				var dashVec = tugVec[i + 1] - tugVec[i]
				if dashVec.length() > .4:
					gust_dash(dashVec,delta)
					
					tugVec[i] = NON_USE_VECTOR
					tugVec[i+1] = NON_USE_VECTOR
	#-------------------------------
	
	
	
	

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
	
	var accel
	
	if moveState != "airDash":
		vel.y += delta*GRAVITY
	elif moveState == "airDash":
		var ADT = $AirDashTimer
		#var dashTimerVelMult = ADT.time_left/(ADT.wait_time * .5)
		vel = vel.normalized() * AIR_DASH_SPEED #* clamp(dashTimerVelMult,0,1)
		
	
	var hvel = vel
	hvel.y = 0
	
	var target = dir
	target *= MAX_SPEED
	
	
	
	
	
	if dir.dot(hvel)<0:
		accel = ACCEL
	elif is_on_floor() && moveState != "airDash" && !weaving:
		accel = GROUND_DEACCEL
	elif weaving:
		accel = WEAVE_DEACCEL
	else:
		accel = 0
	
	
	hvel = hvel.linear_interpolate(target, accel*delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel,Vector3(0,1,0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
	

func process_post_movement(delta):
	#Keep tugVec update with movement
	for vec in tugVec:
		if vec != NON_USE_VECTOR:
			vec += vel

func weave_dash(dashVec,delta):
	var vec = headset.global_transform.basis.z.normalized() * -1
	vec.y = 0
	vec *= 5
	vel += vec


func gust_dash(dashVec,delta):
	
	if $AirDashTimer.is_stopped():
		moveState = "airDash"
		$AirDashTimer.start()
		var vec = dashVec.normalized()
		var magnitude = AIR_DASH_SPEED
		vec *= magnitude * -1
		vec = vec.rotated(Vector3(0,1,0),rotation.y)
		
		
		vel = vec
	

func _on_AirDashTimer_timeout():
	#vel = Vector3()
	
	moveState = "stand"



func tug_dash(dashVec,delta):
	var vec = dashVec.normalized()
	var magnitude = clamp(dashVec.length() * 30,0,200)
	vec *= magnitude * -1
	vec = vec.rotated(Vector3(0,1,0),rotation.y)
	
	
	vel += vec

func VR_con_pressed(controller,button,delta):
	if button == vRConButtons["Trigger"]:
		var tugIndex
		if controller == leftController:
			tugIndex = 0
		if controller == rightController:
			tugIndex = 2
		
		tugVec[tugIndex] = controller.translation#controller.global_transform.origin#controller.translation
		tugVec[tugIndex + 1] = controller.translation#controller.global_transform.origin#controller.translation
	elif button ==vRConButtons["NearButton"]:
		if controller == leftController:
			weaveSide = 1
		elif controller == rightController:
			weaveSide = 2
		weaving = true;

func VR_con_released(controller,button,delta):
	if button == vRConButtons["Trigger"]:
		var tugIndex
		if controller == leftController:
			tugIndex = 0
		if controller == rightController:
			tugIndex = 2
		tugVec[tugIndex] = NON_USE_VECTOR
		tugVec[tugIndex+1] = NON_USE_VECTOR
	elif button ==vRConButtons["NearButton"]:
		weaving = 0;

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





#OLD MOVEMENT
func player_hop(controller,delta):
	var dashVector = controller.global_transform.basis.z.normalized()
	vel = dashVector * -700 * delta
	sounds.play("Hop")
	

