extends KinematicBody
var dBTimer

const GRAVITY = -24.8
const MAX_SPEED = 20
const JUMP_SPEED = 14
const AIR_DASH_SPEED = 20
const WEAVE_SPEED = 10
const GUST_DASH_TUG_MIN = .4
const ACCEL = 4.5
const GROUND_DEACCEL = 12
const AIR_DEACCEL = 6
const WEAVE_DEACCEL = 8
const MAX_SLOPE_ANGLE = 40
const NON_USE_VECTOR = Vector3(-999,-999,-999)
const NON_AUDIBLE_DB = -60
const HIT_FOR_HOMING_DISTANCE = 2

var marker = preload("res://Packed/Marker.tscn")

var moveState = "stand"

var headset
var rightController
var leftController
var sounds
var enemies
#var lastLockedEnemy
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
var weaveGain = -60

var markedEn = null

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
	vRGearPosLog.Head.push_front($ARVROrigin/ARVRCamera.translation)
	vRGearPosLog.Right.push_front($ARVROrigin/OVRControllerRight.translation)
	vRGearPosLog.Left.push_front($ARVROrigin/OVRControllerLeft.translation)
	
	for gearPos in [vRGearPosLog.Head,vRGearPosLog.Right,vRGearPosLog.Left]:
		#dBString += String(gearPos[0]) + "\n"
		if gearPos.size()>5:
			gearPos.pop_back()
	
	#-------------------------------
	#Set position for hitforhoming (UNIMP)
	if false:
		if markedEn != null:
			var vec2Marked = markedEn.get_node("HomingPoint").global_transform.origin - headset.global_transform.origin
			var HFHVec = vec2Marked.normalized() * HIT_FOR_HOMING_DISTANCE
			$HitForHoming.global_transform.origin = headset.global_transform.origin + HFHVec
	#-------------------------------
	

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
		
		#If sound not playing, start it inaudibly
		if $Sounds/WeaveDash.playing == false:
			$Sounds/WeaveDash.playing = true
			$Sounds/WeaveDash.volume_db = -60
			
		var headLog = vRGearPosLog.Head
		var headMovVec = headLog[1] - headLog[0]
		var facingVec = headset.global_transform.basis.z.normalized()
		
		
		
		var weaveCheckVec = Vector3(headMovVec.x,0,headMovVec.z)
		var preRot = weaveCheckVec
		weaveCheckVec = weaveCheckVec.rotated(Vector3(0,1,0),deg2rad(rotation_degrees.y))
		
		
		var rightVec = facingVec.rotated(Vector3(0,1,0),deg2rad(90))
		
		var leftVec = facingVec.rotated(Vector3(0,1,0),deg2rad(-90))
		
		var dBString = ""
		
		#Unimplemented side-specific weaving
		if false:
			var tarVec
			if weaveSide == weaveType.Left:
				tarVec = rightVec
			elif weaveSide == weaveType.Right:
				tarVec = leftVec
		
		var weAreWeaving = false;
		if abs(headMovVec.length()) > .02:
			#dBString += "Forward is: " + String(facingVec) + "\n"
			#dBString += ("Right is: " + String(rightVec)) + "\n"
			#dBString += ("Left is: " + String(leftVec)) + "\n"
			#dBString += ("Moving vec is: " + String(headMovVec)) + "\n"
			
			#dBTimer.myText = dBString
			
			if rad2deg(weaveCheckVec.angle_to(rightVec)) < 45 || \
			rad2deg(weaveCheckVec.angle_to(leftVec)) < 45:
				if is_on_floor():
					#print("gud")
					weave_dash(weaveCheckVec,delta)
					weAreWeaving = true
		
		if weAreWeaving:
			if $Sounds/WeaveDash.volume_db < -15:
				$Sounds/WeaveDash.volume_db += 15
			else:
				$Sounds/WeaveDash.volume_db -= 1
		
		
			
	else:
		if $Sounds/WeaveDash.playing:
			if $Sounds/WeaveDash.volume_db > -60:
				$Sounds/WeaveDash.volume_db -= 1
			else:
				$Sounds/WeaveDash.playing = false
	
	#Weave sound manager
	#-------------------------------
	
	#-------------------------------
	#Management of tugVec array
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
	
	#-------------------------------
	
	#-------------------------------
	#One-handed gust homing dash
	for i in [0,2]:
		var vec
		if i == 0:vec = leftVec
		elif i == 2: vec = rightVec
		
		if markedEn != null:
			if vec.length() > GUST_DASH_TUG_MIN:
				homing_gust(markedEn)
		 
		
	#-------------------------------
	#-------------------------------
	#Two-handed gust dash
	if gustPushing:
		if leftVec.angle_to(rightVec) < 45:
			var avgVec = (leftVec + rightVec)/2
			
			if avgVec.length() > GUST_DASH_TUG_MIN:
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
	
	
	
	
	
	#if dir.dot(hvel)<0:
	#	accel = ACCEL
	#el
	if is_on_floor() && moveState != "airDash":
		accel = GROUND_DEACCEL
		if weaving:
			accel = WEAVE_DEACCEL
	#elif weaving:
	#	accel = WEAVE_DEACCEL
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
	vec *= WEAVE_SPEED
	vel += vec


func gust_dash(dashVec,delta):
	
	if $AirDashTimer.is_stopped():
		moveState = "airDash"
		sounds.play("GustDash")
		$AirDashTimer.start()
		var vec = dashVec.normalized()
		var magnitude = AIR_DASH_SPEED
		vec *= magnitude * -1
		vec = vec.rotated(Vector3(0,1,0),rotation.y)
		
		
		vel = vec
	

func _on_AirDashTimer_timeout():
	#vel = Vector3()
	
	moveState = "stand"

func mark_enemy():
	var facingVec = headset.global_transform.basis.z.normalized() * -1
	var ens = enemies.get_children()
	var ensVecs = []
	for en in ens:
		ensVecs.append((en.global_transform.origin - global_transform.origin))
	
	var leastAng
	var closestEn
	for vec in ensVecs:
		var index = ensVecs.find(vec)
		print("Angle to " + ens[index].name + " is " + String(rad2deg(facingVec.angle_to(vec))))
		if leastAng == null:
			leastAng = facingVec.angle_to(vec)
			closestEn = ens[index]
		elif facingVec.angle_to(vec) < leastAng:
			leastAng = facingVec.angle_to(vec)
			closestEn = ens[index]
	
	print("Closest is " + closestEn.name)
	
	
	
	if closestEn != null && closestEn != markedEn:
		var newMark = marker.instance()
		closestEn.add_child(newMark)
		if markedEn != null:
			if markedEn.get_node("Marker"):
				markedEn.get_node("Marker").queue_free()
		markedEn = closestEn
		
		#Set collision mask for HitForHoming
		#$HitForHoming/CollisionShape.shape = markedEn.get_node("CollisionShape").shape
	
	
	

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
	elif button == vRConButtons["FarButton"]:
		mark_enemy()

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
	

#OLD V2
func tug_dash(dashVec,delta):
	var vec = dashVec.normalized()
	var magnitude = clamp(dashVec.length() * 30,0,200)
	vec *= magnitude * -1
	vec = vec.rotated(Vector3(0,1,0),rotation.y)
	
	
	vel += vec