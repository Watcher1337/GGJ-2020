extends StaticBody2D

signal CanLit(lantern)
signal CannotLit
signal warning

const enemyInst = preload("res://Scenes/Beating_Dummy.tscn")
const extinctLantern = preload("res://Textures/Test_textures/Test_Extinct_lantern.png")
const litLantern = preload("res://Textures/Test_textures/Test_Lit_lantern.png")
const corruptLantern = preload("res://Textures/Test_textures/Test_Corrupt_lantern.png")

var dayNightSystem
var AIsystem

var spawnTimer : Timer 
var maxShield : int = 100
var spawnPosition : int = 1
var countOfChildOnStart : int = 0
var canSpawn : bool = false

export var damageTaken = 20
export var shield : int = 100
export var spawnRate : float = 2
export var countOfEnemiesInOneTime : int = 5
export var timerIncreaseTime : float = 15

var LitArea: CollisionShape2D

var stateForEnemys = 0

enum corruptStates {LIT, EXTINCT, CORRUPT}
var corruptState

var lightSource: Light2D

# Called when the node enters the scene tree for the first time.
func _ready():
	corruptState = corruptStates.CORRUPT
	countOfChildOnStart = get_child_count()
	spawnTimer = get_node("SpawnTimer")
	spawnTimer.wait_time = spawnRate
	spawnTimer.start()
	var sprite : Sprite = get_node("Light2D/Sprite")
	sprite.set_texture(litLantern)
	dayNightSystem = get_parent().get_node("DayNightSystem")
	dayNightSystem.connect("nightEnd", self, "nightEnd")
	dayNightSystem.connect("dayEnd", self, "dayEnd")
	
	AIsystem = get_parent().get_node("AIsystem")
	lightSource = get_node("Light2D")

func _process(delta):
	if(corruptState == corruptStates.CORRUPT) and canSpawn:
		spawnNewEnemies(delta)

func spawnNewEnemies(delta) :
	if (spawnTimer.time_left == 0 ) : 
		if(get_child_count() < countOfEnemiesInOneTime + countOfChildOnStart):
			var enemy = enemyInst.instance()
			enemy.state = stateForEnemys
			enemy.connect("death", self, "enemyDeath")
			var spawnerName : String = "SpawnPosition" + str(spawnPosition)
			var position : Vector2 = get_node(spawnerName).position
			enemy.position = position
			spawnPosition += 1
			if(spawnPosition > 4):
				spawnPosition = 1
			self.add_child(enemy)
			AIsystem.addNewEnemy(enemy)
		spawnTimer.start()

func enemyDeath():
	get_parent().increaseScore(100)
	if corruptState == corruptStates.CORRUPT:
		decreaseCorrupt(damageTaken)

func decreaseCorrupt(count : int) :
	shield -= count
	if(shield <= 0):
		extinct()
		killAndRegen()

func _on_LitLatternArea_area_entered(area):
	if area.is_in_group("player") : 
		print("CAN LIT")
		emit_signal("CanLit", self)

func _on_LitLatternArea_area_exited(area):
	emit_signal("CannotLit")
	
func corrupt():
	corruptState = corruptStates.CORRUPT
	var sprite : Sprite = get_node("Light2D/Sprite")
	lightSource.set("enabled", false)
	sprite.set_texture(corruptLantern)
	
func extinct():
	corruptState = corruptStates.EXTINCT
	var sprite : Sprite = get_node("Light2D/Sprite")
	lightSource.set("enabled", false)
	sprite.set_texture(extinctLantern)

func lit():
	corruptState = corruptStates.LIT
	get_parent().increaseScore(1000)
	var sprite : Sprite = get_node("Light2D/Sprite")
	lightSource.set("Color", Color( 1, 1, 0, 1 ))
	lightSource.set("enabled", true)	
	sprite.set_texture(litLantern)

func dayEnd():
	canSpawn = true

func nightEnd():
	killAndRegen()
	canSpawn = false

func killAndRegen(): # Kill all minions remainig - taking damage - and regen this amount hp
	for i in get_children():
		if i is KinematicBody2D:
			i.takeDamage()
			shield += damageTaken

func playerTryLit():
	if corruptState == corruptStates.EXTINCT:
		increaseNightTimer()
		lit()

func increaseNightTimer():
	var buf = dayNightSystem.nightTimer.time_left
	dayNightSystem.nightTimer.stop()
	dayNightSystem.nightTimer.set_wait_time( buf + timerIncreaseTime)
	dayNightSystem.nightTimer.start()

func _on_Area2D_area_entered(area):
	if(area.is_in_group("player")):
		print("SetWarning")
		emit_signal("warning")
		stateForEnemys = 1
