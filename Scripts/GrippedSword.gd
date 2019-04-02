extends Spatial

var hitStep = 0
var hitBody

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass



func _on_BladeEnd_area_entered(area):
	if area == hitBody: 
		if hitStep == 1:
			hitStep = 2
			#print("Swrd 2")
		else:
			hitStep = 0
			#print("Step Reset to " + String(hitStep))


func _on_BladeEdge_area_exited(area):
	if area == hitBody: 
		if hitStep == 2:
			hitStep = 3
			#print("Swrd 3")
		else:
			hitStep = 0
			#print("Step Reset to " + String(hitStep))


func _on_BladeEnd_area_exited(area):
	if area == hitBody: 
		if hitStep == 3:
			hitStep = 0
			#print("Swrd End")
			
			if area.has_method("sword_hit"):
				hit(area)
		else:
			hitStep = 0
			#print("Step Reset to " + String(hitStep))


func _on_BladeEdge_body_entered(body):
	#if body.name == "Coob":
		#print("Entered")
		#print(body.get_groups())
	
	if body.is_in_group("hitable"):
		if hitStep == 0:
			hitBody = body
			hitStep = 1
			print("Swrd 1")
		else:
			hitStep = 0
			print("Step Reset to " + String(hitStep))

func _on_BladeEnd_body_entered(body):
	if body == hitBody: 
		if hitStep == 1:
			hitStep = 2
			print("Swrd 2")
		else:
			hitStep = 0
			print("Step Reset to " + String(hitStep))

func _on_BladeEdge_body_exited(body):
	if body == hitBody: 
		if hitStep == 2:
			hitStep = 3
			print("Swrd 3")
		else:
			hitStep = 0
			print("Step Reset to " + String(hitStep))


func _on_BladeEnd_body_exited(body):
	if body == hitBody: 
		if hitStep == 3:
			hitStep = 0
			print("Swrd End")
			
			if body.has_method("sword_hit"):
				var vec = $SwordGrip/BladeEdge.global_transform.basis.x.normalized()
				
				
				hit(body,vec)
		else:
			hitStep = 0
			print("Step Reset to " + String(hitStep))


func hit(body,hitVector):
	body.sword_hit(hitVector)

