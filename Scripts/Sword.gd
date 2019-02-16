extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	connect("body_entered",self,"_on_body_entered")
	#set_physics_process(true)

func _physics_process(delta):
	pass

func _on_body_entered(body):
	print(body.name)
	if body.has_method("sword_hit"):
		body.sword_hit()