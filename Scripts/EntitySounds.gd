extends Spatial

var sounds = {}

func _ready():
	for i in range(0,get_children().size()):
		var soundNode = get_child(i)
		var soundName = soundNode.name
		sounds[soundName] = soundNode
		#print("Added " + soundName + " on " + get_parent().name)

func play(sound):
	sounds[sound].play()