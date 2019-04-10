extends Timer

var myText = ""

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _on_Debugger_timeout():
	print(myText)
