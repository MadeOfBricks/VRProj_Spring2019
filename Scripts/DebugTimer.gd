extends Timer

var myText = ""


func _on_DebugTimer_timeout():
	var time = OS.get_time()
	var timeString = String(time.hour) + ":" + String(time.minute) + ":" + String(time.second)
	print(timeString + ": " + myText)
