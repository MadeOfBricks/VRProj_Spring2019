extends Spatial

var waveCount = 0
var root

var envFeatures = [preload("res://Packed/TerrainBlock.tscn"),preload("res://Packed/Tree2.tscn")\
	,preload("res://Packed/Tree3.tscn")]
	
var preWaveMenu = preload("res://Packed/PreWaveMenu.tscn")
var enemies = [preload("res://Packed/BasicReap.tscn")]

var enemiesNode 
var envFeaturesNode
var player
var envSoundNode

var hiCorner
var loCorner
var groundXLength
var groundZLength

var loadedPreWaveMenu

func _ready():
	
	randomize()
	root = get_tree().get_root().get_child(0)
	var hiNode = root.get_node("LevGround").get_node("HiCorner").global_transform.origin
	var loNode = root.get_node("LevGround").get_node("LoCorner").global_transform.origin
	hiCorner = Vector2(hiNode.x,hiNode.z)
	loCorner = Vector2(loNode.x,loNode.z)
	groundXLength = hiCorner.x - loCorner.x
	groundZLength = hiCorner.y - loCorner.y
	
	envFeaturesNode = root.get_node("EnvironmentFeatures")
	enemiesNode = root.get_node("Enemies")
	player = root.get_node("Player")
	envSoundNode = root.get_node("EnvironmentSounds")
	
	
	level_reset()

func level_reset():
	print("level_reset called")
	#Set player usermode to gamemenu and sword to sheathed, 2 is code for gamemenu
	player.outside_mode_set(2,self)
	#Increment wave
	waveCount += 1
	
	#Queue free environment features
	for env in envFeaturesNode.get_children():
		env.queue_free()
		
	#Generate new environment features
	var sectorCount = 5.0
	for xMult in range(0,sectorCount):
		for zMult in range(0,sectorCount):
			var sectorStartXZ = Vector2(loCorner.x + groundXLength * (xMult/sectorCount), loCorner.y + groundZLength * (zMult/sectorCount))
			var randomOffset = Vector2(groundXLength * rand_range(0,1/(sectorCount * 2)),groundZLength * rand_range(0,1/(sectorCount * 2)))
			var specificPlaceXZ = sectorStartXZ + randomOffset
			
			var thisFeature
			thisFeature = envFeatures[randi() % envFeatures.size()].instance()
			envFeaturesNode.add_child(thisFeature)
			thisFeature.global_transform.origin = Vector3(specificPlaceXZ.x,0,specificPlaceXZ.y)
			
	
	#Move player back to center
	player.translation = Vector3(0,3.9,0)
	
	#Load pre-wave menu
	var thisMenu = preWaveMenu.instance()
	$PreWavePos.add_child(thisMenu)
	loadedPreWaveMenu = thisMenu
	

func wave_start():
	#Set player mode to game
	player.outside_mode_set(0,self)
	
	#Create enemies
	for i in range(0,waveCount):
		var thisEnemy = enemies[randi() % enemies.size()].instance()
		var randomEnvironThing = envFeaturesNode.get_children()[randi() % envFeaturesNode.get_children().size()]
		var awayVec = Vector3(1,0,0).rotated(Vector3(0,1,0),rand_range(0,2 * PI))
		enemiesNode.add_child(thisEnemy)
		thisEnemy.connect("tree_exited",self,"_on_enemy_death")
		thisEnemy.global_transform.origin = randomEnvironThing.global_transform.origin + awayVec
	
	#Free pre-wave menu
	loadedPreWaveMenu.queue_free()

func _on_enemy_death():
	var count = enemiesNode.get_children().size()
	if count <= 1:
		wave_end()



func wave_end():
	#Play sound to indicate wave is over
	envSoundNode.get_node("FinalHit").play()
	
	#Start timer, level_reset() when time is up
	$NextWaveWait.start()


func _on_NextWaveWait_timeout():
	print("Before level_reset call")
	level_reset()
