extends Spatial

const VALID_FRAME_ANGLE = 60.0
const VALID_FRAMES_CHECKED = 10
const VALID_FRAME_PERCENT_REQUIRED = .5
const TRANSFORM_LOG_SIZE = 15
const HIT_INDEX_MAX = 10
const REQUIRED_HAND_TRAVEL_DISTANCE = .24


var hitBody
var area
var debugger
var sounds

var translationsLog = []
var xBasisLog = []
var handTranslationLog = []

var hitTranslation 
var hitRotation

var hitIndexDifference = HIT_INDEX_MAX

func _ready():
	debugger = get_node("Debugger")
	area = get_node("SwordGrip/Blade")
	sounds = get_node("Sounds")
	for i in range(0,TRANSFORM_LOG_SIZE):
		translationsLog.push_front(area.global_transform.origin)
		xBasisLog.push_front(area.global_transform.basis.x)
		handTranslationLog.push_front(global_transform.origin)

func _physics_process(delta):
	translationsLog.push_front(area.global_transform.origin)
	translationsLog.pop_back()
	xBasisLog.push_front(area.global_transform.basis.x)
	xBasisLog.pop_back()
	handTranslationLog.push_front(global_transform.origin)
	handTranslationLog.pop_back()
	
	if hitIndexDifference <= HIT_INDEX_MAX:
		hitIndexDifference += 1


func hit(body,hitVector):
	body.sword_hit(hitVector)


func _on_Blade_body_entered(body):
	$ValidHit.start()
	hitIndexDifference = 1


func _on_Blade_body_exited(body):
	if body.is_in_group("hitable"):
		var validFrames = 0
		var framesChecked = 0
		for i in range(0,clamp(VALID_FRAMES_CHECKED + 1,0,hitIndexDifference)):
			var this = i
			var last = i+1
			var translationDifference = translationsLog[last] - translationsLog[this]
			var edgeMovementAngleDifference = rad2deg(translationDifference.angle_to(xBasisLog[this] * -1))
			#print("this translation is " + String(translationsLog[this]))
			#print("translationDifference " + String(this) + " is " + String(translationDifference))
			#print("edgeMoveDifference " + String(this) + " is " + String(edgeMovementAngleDifference))
			framesChecked += 1
			if edgeMovementAngleDifference < VALID_FRAME_ANGLE:
				validFrames += 1
		
		print("Out of " + String(framesChecked) + " frames checked")
		print(String(validFrames) + " valid frames")
		print(String(validFrames/framesChecked) + " frames valid")
		
		var handDistance = (handTranslationLog[framesChecked] - handTranslationLog[0]).length()
		
		print("Hand traveled " + String(handDistance))
		print("Required distance is " + String(REQUIRED_HAND_TRAVEL_DISTANCE))
		var goodTime = false
		if $ValidHit.time_left >= 0:
			#print("ValidTimer okay")
			goodTime = true
		else:
			pass#print("ValidTimer timed out")
		
		
		if validFrames/framesChecked >= VALID_FRAME_PERCENT_REQUIRED && goodTime \
		&& handDistance > REQUIRED_HAND_TRAVEL_DISTANCE:
			print("Valid hit")
			var vec = $SwordGrip/Blade.global_transform.basis.x.normalized()
			hit(body,vec)
			sounds.play("GoodHit")
		else:
			sounds.play("BadHit")
			print("Hit invalid")


