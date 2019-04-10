extends StaticBody


const FLOAT_SPEED = 10
const ROTATE_SPEED = .05
const HANGBACK_MAX_DISTANCE = 40
const HANGBACK_MIN_DISTANCE = 20
const ATTACK_TRIGGER_DISTANCE_MIN = 5
const MELEE_PREPARE_DEACCEL = 2
const DASH_SPEED = 40
const ATTACK_DASH_SPEED = 60
const DEACCEL = .5


var root
var sounds
var anim
var player

var preFlinchState = 0
var health = 2
var vel = Vector3()
var approachOffset

var modes = {"Full":0,"Dummy":1,"Disable":2}
var myMode = modes.Full

var states = {"HangBack":0,"Approach":1,"RangedPrepare":2,"MeleePrepare":3,"MeleeAttack":4,\
"RangedAttack":5,"AttackRecovery":6,"Retreat":7,"Flinch":8,"Death":9}
var myState
var hangBackAngle
var attackTargetVec = Vector3()

func _ready():
	randomize()
	sounds = $Sounds
	root = get_tree().get_root().get_child(0)
	anim = get_node("AnimationPlayer")
	player = root.get_node("Player")
	approachOffset = deg2rad(rand_range(-10,10))
	state_change(states.Approach)


func _physics_process(delta):
	process_state(delta)
	process_movement(delta)

func process_state(delta):
	#Variables for use in multiple states
	var vecToPlayer = player.global_transform.origin - global_transform.origin
	var playDist = vecToPlayer.length()
	
	#Player is alive
	#Full AI behavior
	if myMode == modes.Full && player.userMode != 3:
		#Approach State
		if myState == states.Approach:
			var tarVec
			rotate_towards(player)
			tarVec = player.global_transform.origin - global_transform.origin
			tarVec.y = 0
			tarVec = tarVec.rotated(Vector3(0,1,0),approachOffset)
			tarVec = tarVec.normalized()
			dash(tarVec, DASH_SPEED)
			if playDist < ATTACK_TRIGGER_DISTANCE_MIN:
				state_change(states.MeleePrepare)

		#HangBack state
		elif myState == states.HangBack:
			var approachWait = get_node("Timers/WaitToApproach")
			if approachWait.is_stopped():
				approachWait.start()

			rotate_towards(player)

			var tarVec = player.global_transform.origin - global_transform.origin
			tarVec.y = 0

			#When too close
			if playDist < HANGBACK_MIN_DISTANCE:
				tarVec = tarVec.rotated(Vector3(0,1,0),deg2rad(180))
				tarVec = tarVec.rotated(Vector3(0,1,0),approachOffset)
			#When too far
			elif playDist < HANGBACK_MAX_DISTANCE:
				tarVec = tarVec.rotated(Vector3(0,1,0),hangBackAngle)
				tarVec = tarVec.rotated(Vector3(0,1,0),approachOffset)


			tarVec = tarVec.normalized()
			dash(tarVec, DASH_SPEED)
		elif myState == states.MeleePrepare:
			if $Timers/AttackStart.time_left > .5 * $Timers/AttackStart.wait_time:
				rotate_towards(player)
				attackTargetVec = vecToPlayer
				attackTargetVec.y = 0



func process_movement(delta):

	#MeleePrepare state
	if myState == states.MeleePrepare:
		vel = vel.normalized() * (vel.length() - MELEE_PREPARE_DEACCEL)

	vel = vel.normalized() * (vel.length() - DEACCEL)
	var thisFrameVel = vel * delta
	translate(thisFrameVel)

func state_change(state,arg0 = null):
	if state == states.Approach:
		myState = state
	elif state == states.HangBack:
		hangBackAngle = deg2rad(sign(rand_range(-1,1)) * 90 + rand_range(-10,10))
		myState = state
	elif state == states.MeleePrepare:
		anim.play("Wind Back")
		$Timers/AttackStart.start()
		myState = state
	elif state == states.MeleeAttack:
		myState = state
		anim.play("Swing")
		$Timers/AttackCooldown.start()
		dash(attackTargetVec,ATTACK_DASH_SPEED,true)
	elif state == states.AttackRecovery:
		anim.play("Resume Idle")
	elif state == states.Flinch:
		#Save previous state
		preFlinchState = myState
		myState = state

		#Flinch Movement
		var hitVector = arg0
		var awayVec = $Meshes/Torso/Skull.global_transform.origin - \
		player.get_node("ARVROrigin/ARVRCamera").global_transform.origin
		var flinchVector = awayVec
		dash(flinchVector,DASH_SPEED * .3,true)
		var forwardVec = $Meshes.global_transform.basis.z.normalized()
		var rightVec = forwardVec.rotated(Vector3(0,1,0),deg2rad(-90))
		var leftVec = forwardVec.rotated(Vector3(0,1,0),deg2rad(90))
		var rightAngDiff = hitVector.angle_to(rightVec)
		var leftAngDiff = hitVector.angle_to(leftVec)

		var anims = ["FlinchR","FlinchL"]
		if rightAngDiff < leftAngDiff:
			anim.play(anims[0])
		else:
			anim.play(anims[1])

		#Reset timers
		$Timers.reset_all()

		#Start Flinch Timer
		$Timers/FlinchRecover.start()

		#Decrement Health
		health-= 1
		sounds.play("Hit")
		if health <= 0:
			destroy()



func dash(vec, speed,override = false):
	if $Timers/DashCooldown.is_stopped() || override:
		$Timers/DashCooldown.start()
		vel = vec.normalized() * speed


func rotate_towards(target):
	var tarVec2Pos = Vector2(target.global_transform.origin.x,target.global_transform.origin.z)
	var myVec2Pos = Vector2(global_transform.origin.x,global_transform.origin.z)

	var vec2Tar = myVec2Pos - tarVec2Pos
	var facingVec = $Meshes.global_transform.basis.xform(Vector3(0,0,1)) * -1
	var vec2FacingVec = Vector2(facingVec.x,facingVec.z)
	var angleTo = vec2FacingVec.angle_to(vec2Tar) * -1

	if abs(angleTo) >= ROTATE_SPEED:
		$Meshes.rotate(Vector3(0,1,0),sign(angleTo) * ROTATE_SPEED)


func sword_hit(hitVector):
	#TODO: Replace with state_change("flinch")
	state_change(states.Flinch,hitVector)



func destroy():
	$CollisionShape.disabled = true
	$Meshes.visible = false
	$Timers/RemoveTimer.start()

func _on_RemoveTimer_timeout():
	queue_free()


func _on_AttackStart_timeout():
	state_change(states.MeleeAttack)


func _on_AttackCooldown_timeout():
	state_change(states.AttackRecovery)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Resume Idle":
		state_change(states.HangBack)
	#elif anim_name == "FlinchR" ||\
	#anim_name == "FlinchL":
		#pass
	elif anim_name == "Swing":
		anim.play("SwingEnd")


func _on_WaitToApproach_timeout():
	state_change(states.Approach)


func _on_ScytheBlade_body_entered(body):
	var timeString = String(OS.get_time().minute) + ":" + String(OS.get_time().second)
	if anim.current_animation == "Swing":
		if body.name == "Player":
			sounds.play("Hit")
			body.hit_by_enemy(self)



func _on_FlinchRecover_timeout():
	state_change(states.HangBack)
