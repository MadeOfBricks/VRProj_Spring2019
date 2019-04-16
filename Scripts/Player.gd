extends KinematicBody

var dBTimer
var root

const GRAVITY = -24.8
const MAX_SPEED = 20
const JUMP_SPEED = 14
const GUST_DASH_SPEED = 15
const GUST_DASH_MAX = 1
const WEAVE_SPEED = 10
const GUST_DASH_TUG_MIN = .4
const HOMING_DASH_SPEED = 30
const HOMING_DISTANCE_RANGE_MAX = 15
const HOMING_DISTANCE_MIN = 4.3
const HIT_AWAY_SPEED = 10
const HEALTH_MAX = 1
const ACCEL = 4.5
const GROUND_DEACCEL = 12
const AIR_DEACCEL = 6
const WEAVE_DEACCEL = 8
const MAX_SLOPE_ANGLE = 40
const NON_USE_VECTOR = Vector3(-999,-999,-999)
const NON_AUDIBLE_DB = -60
const HIT_FOR_HOMING_DISTANCE = 2

var marker = preload("res://Packed/Marker.tscn")
var gameMenu = preload("res://Packed/GameMenu.tscn")
var packedSword = preload("res://Packed/GrippedSword.tscn")
var deathMenu = preload("res://Packed/DeathMenu.tscn")

var uModes = {"Game":0,"Menu":1,"GameMenu":2,"Dead":3}
var userMode

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

var loadGameMenu = [false,false]
var loadedGameMenu = null

var health = HEALTH_MAX

var tugVec = [NON_USE_VECTOR,NON_USE_VECTOR,NON_USE_VECTOR,NON_USE_VECTOR]

var availableAirDashes = GUST_DASH_MAX

var homingDashReady = false

#var weaveType = {"Left":1,"Right":2}
var weaveButtons = {"Left":false,"Right":false}
var weaves
var weaving = false
var weaveSide = 0
#var weaveGain = -60

var markedEn
var markedEnName

var swordSheathed = true
var handsReadytoDraw = {"Left":false,"Right":false}
var swordInHand = "None"

var gleamPower = {"Left":0,"Right":0}

func _ready():
	root = get_tree().get_root().get_child(0)
	dBTimer = get_parent().get_node("DebugTimer")
		
	
	if root.name == "RootMainMenu":
		userMode = uModes.Menu
	elif root.name == "RootLevel" || root.name == "RootPlayground" :
		userMode = uModes.Game
	
	
	
	
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
	#Distance to marked enemy
	if markedEn != null:
		if root.get_node("Enemies").get_node(markedEnName):
			var vec2En = markedEn.global_transform.origin - global_transform.origin
			if vec2En.length() < HOMING_DISTANCE_RANGE_MAX:
				markedEn.get_node("Marker").use_mesh("yellow")
				homingDashReady = true
			else:
				homingDashReady = false
				markedEn.get_node("Marker").use_mesh("purple")
		else:
			markedEn = null
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
		
	if userMode == uModes.Game:
		#-------------------------------
		#Weave-dashing
		if weaveButtons.Left || weaveButtons.Right:
			weaving = true
			
			var headLog = vRGearPosLog.Head
			var headMovVec = headLog[1] - headLog[0]
			var facingVec = headset.global_transform.basis.z.normalized()
			
			
			var weaveCheckVec = Vector3(headMovVec.x,0,headMovVec.z)
			var preRot = weaveCheckVec
			weaveCheckVec = weaveCheckVec.rotated(Vector3(0,1,0),deg2rad(rotation_degrees.y))
			
			var forwardVec = headset.global_transform.basis.z.normalized() * -1
			var rightVec = facingVec.rotated(Vector3(0,1,0),deg2rad(-90))
			var leftVec = facingVec.rotated(Vector3(0,1,0),deg2rad(90))
			var dBString = ""
			
			
			var weAreWeaving = false;
			if abs(headMovVec.length()) > .02:
				
				#Decide weave mode
				var mode
				#Forward Weave
				if weaveButtons.Left && weaveButtons.Right:
					mode = "Forward"
				else:
					#Left Weave
					if weaveButtons.Left:
						mode = "Left"
					#Right Weave
					if weaveButtons.Right:
						mode = "Right"
				
				#if rad2deg(weaveCheckVec.angle_to(rightVec)) < 45 || \
				#rad2deg(weaveCheckVec.angle_to(leftVec)) < 45:
				if is_on_floor():
					var leftVecDifference = rad2deg(weaveCheckVec.angle_to(leftVec))
					var rightVecDifference = rad2deg(weaveCheckVec.angle_to(rightVec))
					
					var dashVec
					
					if mode == "Left":
						if leftVecDifference < 45:
							dashVec = forwardVec.rotated(Vector3(0,1,0),deg2rad(90))
							weave_dash(dashVec,delta)
					elif mode == "Right":
						if rightVecDifference < 45:
							dashVec = forwardVec.rotated(Vector3(0,1,0),deg2rad(-90))
							weave_dash(dashVec,delta)
					elif mode == "Forward":
						if rightVecDifference < 45 || leftVecDifference < 45:
							weave_dash(forwardVec,delta)
					
					
					weAreWeaving = true
					
					
					#Just play the sound
					if !$Sounds/WeaveDash.playing:
						$Sounds/WeaveDash.play()
			
			
			
				
		else:
			#Dynamically reduce weave dash volume (UNIMP)
			if false:
				if $Sounds/WeaveDash.playing:
					if $Sounds/WeaveDash.volume_db > -60:
						$Sounds/WeaveDash.volume_db -= 1
					else:
						$Sounds/WeaveDash.playing = false
		
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
			if tugVec[i] != NON_USE_VECTOR:
				var otherHandNotTugging = false
				var vec
				if i == 0:
					vec = leftVec
					if tugVec[2] == NON_USE_VECTOR:
						otherHandNotTugging = true
				elif i == 2: 
					vec = rightVec
					if tugVec[0] == NON_USE_VECTOR:
						otherHandNotTugging = true
				
				if markedEn != null && otherHandNotTugging && homingDashReady:
					if root.get_node("Enemies").has_node(markedEnName):
						var randInt = rand_range(0,10)
						var vec2Enemy = (markedEn.global_transform.origin - global_transform.origin)
						var vec2EnemyRot = vec2Enemy.rotated(Vector3(0,1,0),deg2rad(rotation_degrees.y * -1))
						
						if vec.length() > GUST_DASH_TUG_MIN \
						&& vec.angle_to(vec2EnemyRot) < deg2rad(45):
							homing_gust(markedEn)
							tugVec[i] = NON_USE_VECTOR
							tugVec[i+1] = NON_USE_VECTOR
					else:
						markedEn = null
		#-------------------------------
		#-------------------------------
		#Two-handed gust dash
		if gustPushing && availableAirDashes > 0:
			if leftVec.angle_to(rightVec) < deg2rad(45):
				var avgVec = (leftVec + rightVec)/2
				
				if avgVec.length() > GUST_DASH_TUG_MIN:
					gust_dash(avgVec,delta)
					availableAirDashes -= 1
					
					for i in range(0,4):
						tugVec[i] = NON_USE_VECTOR
					
		#-------------------------------
		
		#-------------------------------
		#Open menu
		if loadedGameMenu == null:
			if loadGameMenu[0] && loadGameMenu[1]:
				var gMenu = gameMenu.instance()
				add_child(gMenu)
				loadedGameMenu = gMenu
		#-------------------------------
	
	

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
	#Move us towards target if homingDashing
	if moveState == "homingDash":
		var vec = (markedEn.global_transform.origin - global_transform.origin).normalized()
		vec *= HOMING_DASH_SPEED
		vel = vec
		
		var distVec = markedEn.global_transform.origin - global_transform.origin
		if distVec.length() < HOMING_DISTANCE_MIN:
			moveState = "stand"
	
	var accel
	
	#Apply gravity
	if moveState != "airDash" && moveState != "homingDash":
		vel.y += delta*GRAVITY
	#Unless we're air-dashing
	elif moveState == "airDash":
		var ADT = $AirDashTimer
		vel = vel.normalized() * GUST_DASH_SPEED 
		
	
	var hvel = vel
	hvel.y = 0
	
	var target = dir
	target *= MAX_SPEED
	
	
	#Surface-dependent code
	if is_on_floor():
		#Regain air dashes
		availableAirDashes = GUST_DASH_MAX
		if moveState != "airDash" && moveState != "homingDash":
			#Deacceleration on floor, if not dashing
			accel = GROUND_DEACCEL
			if weaving:
				accel = WEAVE_DEACCEL
		else:
			accel = 0
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

func gleam_add(count,hand):
	var con
	var setTo
	if hand == "Left":
		con = leftController
		gleamPower.Left = clamp(gleamPower.Left,0,gleamPower.Left + count)
		setTo = gleamPower.Left
	elif hand == "Right":
		con = rightController
		gleamPower.Right = clamp(gleamPower.Right,0,gleamPower.Right + count)
		setTo = gleamPower.Right
	
	
	con.get_node("Hand/HandGleam").set_gleam(setTo)


func hit_by_enemy(enemy):
	
	#Knockback
	var vecAway = global_transform.origin - enemy.global_transform.origin.normalized()
	vecAway.y = 1
	vecAway = vecAway.normalized()
	var magnitude = HIT_AWAY_SPEED
	vecAway *= magnitude
	vel = vecAway
	
	#Health Decrement
	health -= 1
	if health <= 0:
		player_death()


func game_menu_removed():
	loadedGameMenu = null
	userMode = uModes.Game


func start_hit_float():
	moveState = "hitFloat"
	$HitFloatTimer.start()

func homing_gust(enemy):
	moveState = "homingDash"
	sounds.play("GustDash")
	var vec = (enemy.global_transform.origin - global_transform.origin).normalized()
	vec *= HOMING_DASH_SPEED
	vel = vec

func weave_dash(dashVec,delta):
	#var vec = headset.global_transform.basis.z.normalized() * -1
	var vec = dashVec
	vec.y = 0
	vec *= WEAVE_SPEED
	vel += vec


func gust_dash(dashVec,delta):
	
	if $AirDashTimer.is_stopped():
		moveState = "airDash"
		sounds.play("GustDash")
		$AirDashTimer.start()
		var vec = dashVec.normalized()
		var magnitude = GUST_DASH_SPEED
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
		if leastAng == null:
			leastAng = facingVec.angle_to(vec)
			closestEn = ens[index]
		elif facingVec.angle_to(vec) < leastAng:
			leastAng = facingVec.angle_to(vec)
			closestEn = ens[index]
	
	if closestEn != null && closestEn != markedEn:
		var newMark = marker.instance()
		if markedEn != null:
			if markedEn.has_node("Marker"):
				markedEn.get_node("Marker").queue_free()
		closestEn.add_child(newMark)
		markedEn = closestEn
		markedEnName = markedEn.name
	
		#Set collision mask for HitForHoming
		#$HitForHoming/CollisionShape.shape = markedEn.get_node("CollisionShape").shape


func player_death():
	#Sheath sword
	var con
	if swordInHand == "Left":
		con = leftController
	elif swordInHand == "Right":
		con = rightController
	if con != null:
		var sword = con.get_node("GrippedSword")
		if sword:
			sword.queue_free()
			swordSheathed = true
	
	#Change mode
	userMode = uModes.Dead
	
	#Load death menu
	var dMenu = deathMenu.instance()
	print("Adding Death Menu")
	add_child(dMenu)
	print("DMenu at " + String(dMenu.global_transform.origin))
	

func _on_SheathArea_area_entered(area):
	if userMode == uModes.Game:
		if area.name == "MenuPresser":
			var controllerParent = area.get_parent().get_parent()
			if controllerParent == leftController:
				handsReadytoDraw.Left = true
			elif controllerParent == rightController:
				handsReadytoDraw.Right = true
		


func _on_SheathArea_area_exited(area):
	if userMode == uModes.Game:
		if area.name == "MenuPresser":
			var controllerParent = area.get_parent().get_parent()
			if controllerParent == leftController:
				handsReadytoDraw.Left = false
			elif controllerParent == rightController:
				handsReadytoDraw.Right = false
	
	

	
	
	

func VR_con_pressed(controller,button,delta):
	if button == vRConButtons["Grip"]:
		if swordSheathed:
			var con
			var canConGrab = false
			var swordString = "None"
			if controller == leftController:
				con = leftController
				canConGrab = handsReadytoDraw.Left
				swordString = "Left"
			elif controller == rightController:
				con = rightController
				canConGrab = handsReadytoDraw.Right
				swordString = "Right"
			
			if canConGrab:
				var newSword = packedSword.instance()
				con.add_child(newSword)
				swordSheathed = false
				swordInHand = swordString
				sounds.play("SwordDraw")
		else:
			var con
			var canConSheathe = false
			if controller == leftController:
				con = leftController
				if swordInHand == "Left":
					canConSheathe = handsReadytoDraw.Left
			elif controller == rightController:
				con = rightController
				if swordInHand == "Right":
					canConSheathe = handsReadytoDraw.Right
			
			if canConSheathe:
				var sword = con.get_node("GrippedSword")
				sword.queue_free()
				swordSheathed = true
				sounds.play("SwordSheath")
				
	if button == vRConButtons["Trigger"]:
		var tugIndex
		if controller == leftController:
			tugIndex = 0
		if controller == rightController:
			tugIndex = 2
		
		tugVec[tugIndex] = controller.translation#controller.global_transform.origin#controller.translation
		tugVec[tugIndex + 1] = controller.translation#controller.global_transform.origin#controller.translation
	elif button ==vRConButtons["NearButton"]:
		#Decide weaving side (UNIMP)
		if false:
			if controller == leftController:
				weaveSide = 1
			elif controller == rightController:
				weaveSide = 2
		
		if controller == leftController:
			weaveButtons.Left = true
		elif controller == rightController:
			weaveButtons.Right = true
		
		#weaving = true;
	elif button == vRConButtons["FarButton"]:
		
		if userMode == uModes.Game:
			if controller == leftController:
				loadGameMenu[0] = true
			else:
				loadGameMenu[1] = true
			
			if moveState != "homingDash":
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
		if controller == leftController:
			weaveButtons.Left = false
		elif controller == rightController:
			weaveButtons.Right = false
	elif button == vRConButtons["FarButton"]:
		if controller == leftController:
			loadGameMenu[0] = false
		else:
			loadGameMenu[1] = false


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


func outside_mode_set(mode,node):
	if node.name == "GameManager":
		#We're assuming this is a reset to the prewave menu
		if mode == uModes.GameMenu:
			rotation_degrees.y = 0
			userMode = mode
			var con
			if swordInHand == "Left":
				con = leftController
			elif swordInHand == "Right":
				con = rightController
			
			if con != null:
				var sword = con.get_node("GrippedSword")
				if sword:
					sword.queue_free()
					swordSheathed = true
		elif mode == uModes.Game:
			userMode = mode

		
	
