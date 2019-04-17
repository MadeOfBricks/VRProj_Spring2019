extends Spatial

const ENV_FEATURE_SECTOR_COUNT = 7.0
const ENV_FEATURE_MAKE_CHANCE = .5
const MIN_ENEMY_DISTANCE_TO_PLAYER = 20

var waveCount = 0
var root

var envFeatures = [preload("res://Packed/Environment/TerrainBlock.tscn"),preload("res://Packed/Environment/Tree2.tscn")\
	,preload("res://Packed/Environment/Tree3.tscn")]
	
var preWaveMenu = preload("res://Packed/PreWaveMenu.tscn")
var enemies = [preload("res://Packed/Enemies/BasicReap.tscn"), preload("res://Packed/Enemies/AggressiveReap.tscn")]

var enemiesNode 
var envFeaturesNode
var player
var envSoundNode

var hiCorner
var loCorner
var groundXLength
var groundZLength

var loadedPreWaveMenu

var enemySpawnLocations = []

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
	#Set player usermode to gamemenu and sword to sheathed, 2 is code for gamemenu
	player.outside_mode_set(2,self)
	#Increment wave
	waveCount += 1
	
	#Queue free environment features
	for env in envFeaturesNode.get_children():
		env.queue_free()
		
	#Generate new environment features
	for xMult in range(0,ENV_FEATURE_SECTOR_COUNT):
		for zMult in range(0,ENV_FEATURE_SECTOR_COUNT):
			#Some location in this sector
			var sectorStartXZ = Vector2(loCorner.x + groundXLength * (xMult/ENV_FEATURE_SECTOR_COUNT), loCorner.y + groundZLength * (zMult/ENV_FEATURE_SECTOR_COUNT))
			var randomOffset = Vector2(groundXLength * rand_range(0,1/(ENV_FEATURE_SECTOR_COUNT * 2)),groundZLength * rand_range(0,1/(ENV_FEATURE_SECTOR_COUNT * 2)))
			var specificPlaceXZ = sectorStartXZ + randomOffset
			var spawnLocation = Vector3(sectorStartXZ.x,0,specificPlaceXZ.y)
			#Decide whether we make an environmental feature
			var make = rand_range(0,1)
			if make <= ENV_FEATURE_MAKE_CHANCE:
				
				
				
				var thisFeature
				thisFeature = envFeatures[randi() % envFeatures.size()].instance()
				envFeaturesNode.add_child(thisFeature)
				thisFeature.global_transform.origin = Vector3(specificPlaceXZ.x,0,specificPlaceXZ.y)
				if thisFeature.name.find("TerrainBlock") != -1:
					var rands = Vector3(rand_range(0,360),rand_range(0,360),rand_range(0,360))
					thisFeature.rotation_degrees = rands
				elif thisFeature.name.find("Tree") != -1:
					thisFeature.rotation_degrees.y = rand_range(0,360)
			
			#Decide whether or not this is a valid enemy spawn area
			var playerXZ = Vector2(player.global_transform.origin.x,player.global_transform.origin.z)
			if (specificPlaceXZ - playerXZ).length() > MIN_ENEMY_DISTANCE_TO_PLAYER:
				enemySpawnLocations.append(spawnLocation)
	
	
	#Move player back to center
	player.translation = Vector3(0,3.9,0)
	player.vel = Vector3(0,0,0)
	
	#Set player hands visible
	player.set_hands_visible(true)
	
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
		var spawnPoint
		spawnPoint = enemySpawnLocations[randi() % enemySpawnLocations.size()]
		
		#var awayVec = Vector3(1,0,0).rotated(Vector3(0,1,0),rand_range(0,2 * PI))
		enemiesNode.add_child(thisEnemy)
		thisEnemy.connect("tree_exited",self,"_on_enemy_death")
		thisEnemy.global_transform.origin = spawnPoint 
	
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
