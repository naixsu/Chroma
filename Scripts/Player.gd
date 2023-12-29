extends CharacterBody2D

class_name Player
###
# Grouped to: Player
###

# Export vars here
@export var speed = 300
@export var maxSpeed = speed
@export var dashSpeed = 800
@export var dashLength = 0.3
@export var health = 100
@export var maxHealth = health

@export var dead = false
@export var readyState = false # had to avoid 'ready' builtin keyword
@export var canDash = false

@export var currentWeaponIndex = 0
@export var weapon_held_down = false

@export var respawn = false
@export var displayRespawn = false
@export var money : int = 300

@export var dmgAdd : float
@export var accSub : float
@export var bulletSpeedAdd : float

# Onready vars here
@onready var anim = $AnimatedSprite2D
@onready var multiplayerSynchronizer = $MultiplayerSynchronizer
@onready var weaponsManager = $WeaponsManager
@onready var dash = $Dash
@onready var bombIndicator = $BombIndicator
@onready var playerCamera = $PlayerCamera
@onready var readyPrompt = get_tree().get_root().get_node("TestMultiplayerScene/ReadyPrompt")
@onready var readyLabel = $ReadyLabel
@onready var respawnNode = $Respawn # Avoiding variable names (resoawn)
@onready var respawnLabel = $Respawn/RespawnLabel
@onready var respawnModal = $Respawn/RespawnModal
@onready var respawnTimer = $Respawn/RespawnTimer
@onready var moneyLabel = $MoneyLabel
@onready var shop = $Shop
@onready var nameLabel = $NameLabel
@onready var healthLabel = $HealthLabel

@onready var weaponFile = "res://Scenes/Player/WeaponData.json"
@onready var iFramesTimer = $IFramesTimer
@onready var collision = $CollisionShape2D
@onready var SoundManager = $SoundManager # Capitalizing this

@onready var meleeNode = $WeaponsManager/Melee
@onready var HUD = $HUD
@onready var multiplayerWarning = $MultiplayerWarning

@onready var gunfire = $ParticleFX/gunfire
@onready var runparticles = $ParticleFX/runparticles

# Signals here
signal update_ready
signal upgrade(stat)


# Other global vars here
var spawn_points = []
var tempSpeed = maxSpeed
var weapons
var weaponsData: Array = []
var currentWeapon

# Shop stuff
var playerShop
var playerAnim2D
var healthProgressBar
var speedProgressBar
var dashProgressBar
var hb
var sb
var db
var playerPrices

var pistolShop
var pistolDmgProgressBar
var pistolAccProgressBar
var pistolBSProgressBar
var pdb # damage button
var pab # acc button
var pbb # bulletspeed button
var pistolPrices

var rifleShop
var rifleDmgProgressBar
var rifleAccProgressBar
var rifleBSProgressBar
var rdb
var rab
var rbb
var riflePrices

var shotgunShop
var shotgunDmgProgressBar
var shotgunAccProgressBar
var shotgunBSProgressBar
var sdb
var sab
var sbb
var shotgunPrices

var meleeShop
var meleeDmgProgressBar
var mdb
var meleePrices

var shopMoneyLabel

var shopButtons = []
var shopPrices = []
var shopPricesDisplay = []
var weaponUpgrades : Dictionary

@export var showIframes = false

func _ready():
	init_weapons(weaponFile)
	init_shop()
	
	readyPrompt.connect("toggle_ready", toggle_ready)
	shop.connect("upgrade", player_upgrade)
	meleeNode.connect("finished_anim", finished_anim)

	multiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	# Set the camera and hud
	# to only be active for the local player
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		playerCamera.make_current()
		HUD.visible = true
		update_hud.rpc()

	anim.play("idle")
	nameLabel.text = str(GameManager.players[name.to_int()].name)
	
func _process(_delta):
	if GameManager.gameOver: return 
	
	readyLabel.text = str(readyState)
	moneyLabel.text = str(money)
	healthLabel.text = str(health)
	
	if respawn:
		if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
			respawnTimer.start()
			respawnLabel.show()
			respawnModal.show()
			displayRespawn = true
	
	if displayRespawn: 
		display_respawn()


func _physics_process(_delta):
	if GameManager.gameOver: return 
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		if showIframes:
			var mapped_value = iFramesTimer.time_left / iFramesTimer.wait_time
			var iFramesModulate = lerp(0, 1, 1.0 - mapped_value)

			anim.set_self_modulate(Color(1, 1, 1, iFramesModulate))

		var direction = Input.get_vector("Left", "Right", "Up", "Down")
		
		if dash.is_dashing():
			velocity = direction * dashSpeed
		else:
			velocity = direction * speed
		
		if not dead:
			move_and_slide()
			update_gun_rotation()
			update_animation()
			check_hit()

	update_camera()
	update_bomb_indicator_rotation()
	
func _unhandled_input(event): 
	if GameManager.gameOver: return 

	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id() and not dead:
		if Input.is_action_just_pressed("Dash") and canDash and dash.dashCooldown.is_stopped():
			var mouse_direction = get_local_mouse_position().normalized()
			velocity = Vector2(dashSpeed * mouse_direction.x, dashSpeed * mouse_direction.y)
			dash.start_dash(dashLength)
			runparticles.emitting = true
			SoundManager.playerDash.play()
			
		if event.is_action_pressed("Fire"):
			fire.rpc(true)
			
		if event.is_action_released("Fire"):
			fire.rpc(false)
			
		if event.is_action_pressed("SwitchWeapon1") and currentWeaponIndex != 0:
			switch_weapon.rpc(0)

		if event.is_action_pressed("SwitchWeapon2") and currentWeaponIndex != 1:
			switch_weapon.rpc(1)

		if event.is_action_pressed("SwitchWeapon3") and currentWeaponIndex != 2:
			switch_weapon.rpc(2)

		if event.is_action_pressed("SwitchWeapon4") and currentWeaponIndex != 3:
			switch_weapon.rpc(3)
		
		if event.is_action_pressed("Escape"):
			multiplayerWarning.warn()
		
		update_hud.rpc()

func init_weapons(file):
	# Init from weaponFile
	var f = FileAccess.open(file, FileAccess.READ)
	var content = f.get_as_text()
	weaponsData = JSON.parse_string(content)	
	weapons = weaponsManager.get_child(0)
	currentWeapon = weapons
	currentWeapon.get_node("FireCooldown").wait_time = weaponsData[currentWeaponIndex].wait_time

func init_shop():
	print("Initializing shop")
	playerShop = shop.get_node("TabContainer").get_node("Player")
	playerAnim2D = playerShop.get_node("Panel").get_node("Player")
	playerAnim2D = self.anim
	healthProgressBar = playerShop.get_node("Health").get_node("ProgressBar")
	speedProgressBar = playerShop.get_node("Speed").get_node("ProgressBar")
	dashProgressBar = playerShop.get_node("Dash").get_node("ProgressBar")
	hb = playerShop.get_node("Health").get_node("HealthButton")
	sb = playerShop.get_node("Speed").get_node("SpeedButton")
	db = playerShop.get_node("Dash").get_node("DashButton")
	playerPrices = playerShop.get_node("Prices").get_children()

	pistolShop = shop.get_node("TabContainer").get_node("Pistol")
	pistolDmgProgressBar = pistolShop.get_node("Damage").get_node("ProgressBar")
	pistolAccProgressBar = pistolShop.get_node("Accuracy").get_node("ProgressBar")
	pistolBSProgressBar = pistolShop.get_node("Bulletspeed").get_node("ProgressBar")
	pdb = pistolShop.get_node("Damage").get_node("PDmgButton")
	pab = pistolShop.get_node("Accuracy").get_node("PAccButton")
	pbb = pistolShop.get_node("Bulletspeed").get_node("PBSButton")
	pistolPrices = pistolShop.get_node("Prices").get_children()
	
	rifleShop = shop.get_node("TabContainer").get_node("Rifle")
	rifleDmgProgressBar = rifleShop.get_node("Damage").get_node("ProgressBar")
	rifleAccProgressBar = rifleShop.get_node("Accuracy").get_node("ProgressBar")
	rifleBSProgressBar = rifleShop.get_node("Bulletspeed").get_node("ProgressBar")
	rdb = rifleShop.get_node("Damage").get_node("RDmgButton")
	rab = rifleShop.get_node("Accuracy").get_node("RAccButton")
	rbb = rifleShop.get_node("Bulletspeed").get_node("RBSButton")
	riflePrices = rifleShop.get_node("Prices").get_children()
	
	shotgunShop = shop.get_node("TabContainer").get_node("Shotgun")
	shotgunDmgProgressBar = shotgunShop.get_node("Damage").get_node("ProgressBar")
	shotgunAccProgressBar = shotgunShop.get_node("Accuracy").get_node("ProgressBar")
	shotgunBSProgressBar = shotgunShop.get_node("Bulletspeed").get_node("ProgressBar")
	sdb = shotgunShop.get_node("Damage").get_node("SDmgButton")
	sab = shotgunShop.get_node("Accuracy").get_node("SAccButton")
	sbb = shotgunShop.get_node("Bulletspeed").get_node("SBSButton")
	shotgunPrices = shotgunShop.get_node("Prices").get_children()
	
	meleeShop = shop.get_node("TabContainer").get_node("Melee")
	meleeDmgProgressBar = meleeShop.get_node("Damage").get_node("ProgressBar")
	mdb = meleeShop.get_node("Damage").get_node("MDmgButton")
	meleePrices = meleeShop.get_node("Prices").get_children()
	
	shopMoneyLabel = shop.get_node("Money").get_node("MoneyLabel")
	
	# HARDCODED
	# THESE HAVE TO BE IN ORDER
	shopButtons = [	hb, sb, db,
					pdb, pab, pbb,
					rdb, rab, rbb,
					sdb, sab, sbb,
					mdb
					]

	shopPrices = [	shop.playerHealthCost, shop.playerSpeedCost, shop.playerDashCost,
					shop.pistolDmgCost, shop.pistolAccCost, shop.pistolBSCost,
					shop.rifleDmgCost, shop.rifleAccCost, shop.rifleBSCost,
					shop.shotgunDmgCost, shop.shotgunAccCost, shop.shotgunBSCost,
					shop.meleeDmgCost
				]
	
	shopPricesDisplay = [
		playerPrices, pistolPrices, riflePrices, shotgunPrices, meleePrices
	]
	
	weaponUpgrades = {
		"pistol": {
			"damage": [pistolDmgProgressBar, shop.pistolDmgCost, 0, 1.25],
			"accuracy": [pistolAccProgressBar, shop.pistolAccCost, 0, 2],
			"bulletSpeed": [pistolBSProgressBar, shop.pistolBSCost, 0, 62.5],
		},

		"rifle": {
			"damage": [rifleDmgProgressBar, shop.rifleDmgCost, 0, 1.5],
			"accuracy": [rifleAccProgressBar, shop.rifleAccCost, 0, 1.25],
			"bulletSpeed": [rifleBSProgressBar, shop.rifleBSCost, 0, 75],
		},

		"shotgun": {
			"damage": [shotgunDmgProgressBar, shop.shotgunDmgCost, 0, 0.5],
			"accuracy": [shotgunAccProgressBar, shop.shotgunAccCost, 0, 7.5],
			"bulletSpeed": [shotgunBSProgressBar, shop.shotgunBSCost, 0, 50],
		},

		"melee": {
			"damage": [meleeDmgProgressBar, shop.meleeDmgCost, 0, 5],
		}
	}
	
	update_money_label()
	update_shop_prices()

@rpc("any_peer", "call_local")
func update_hud():
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		HUD.moneyText.text = str(money)
		# Calculate max health to healthbar
		HUD.healthBar.max_value = maxHealth
		HUD.healthBar.value = health
		
		for buttonIndex in range(HUD.hotBarButtons.size()):
			if buttonIndex == currentWeaponIndex:
				HUD.hotBarButtons[buttonIndex].disabled = false
			else:
				HUD.hotBarButtons[buttonIndex].disabled = true

func update_shop_prices():
	var i = 0
	for shopPrice in shopPricesDisplay:
		for priceDisplay in shopPrice:
			priceDisplay.text = str(shopPrices[i])
			i += 1


func update_money_label():
	shopMoneyLabel.text = str(money) + " Credits"
	update_hud.rpc()
	
@rpc("any_peer", "call_local")
func show_shop():
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		shop.show()
		update_shop_buttons()
		HUD.hide()
		update_hud.rpc()
		
@rpc("any_peer", "call_local")
func hide_shop():
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		shop.hide()
		HUD.show()
		update_hud.rpc()

@rpc("any_peer", "call_local")
func show_ready():
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		readyPrompt.show()
		
@rpc("any_peer", "call_local")
func hide_ready():
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		readyPrompt.hide()

func update_shop_buttons():
	for i in shopButtons.size():
		if money < shopPrices[i]:
			shopButtons[i].hide()
		else:
			shopButtons[i].show()

func player_upgrade(subject, stat):
	upgrade_stats.rpc(subject, stat)

# General upgrade function
@rpc("any_peer", "call_local")
func upgrade_stats(subject, stat):
	print("Upgrade Pressed " + " " + subject + " " + stat )
	match subject:
		"player":
			upgrade_player(stat)
		"pistol":
			upgrade_pistol(stat)
		"rifle":
			upgrade_rifle(stat)
		"shotgun":
			upgrade_shotgun(stat)
		"melee":
			upgrade_melee(stat)

	update_money_label()
	update_shop_buttons()
	update_shop_prices()

func upgrade_player(stat):
	print("Upgrading player " + stat)
	match stat:
		"health":
			health += 25
			maxHealth = health
			healthProgressBar.value += 25
			set_money(-shop.playerHealthCost)
		"speed":
			speed += 25
			maxSpeed = speed
			speedProgressBar.value += 25
			set_money(-shop.playerSpeedCost)
		"dash":
			canDash = true
			dashProgressBar.value = 100
			set_money(-shop.playerDashCost)

# General weapon function
func upgrade_weapon(weapon, stat):
	print("Upgrading " + weapon + " " + stat)
	if weaponUpgrades.has(weapon) and weaponUpgrades[weapon].has(stat):
		var values = weaponUpgrades[weapon][stat]
		values[0].value += 25 # Progress Bar Value
		set_money(-values[1]) # Upgrade Cost
		weaponUpgrades[weapon][stat][2] += weaponUpgrades[weapon][stat][3] # Stat - Stat Up

		print(weaponUpgrades[weapon])

func upgrade_pistol(stat):
	upgrade_weapon("pistol", stat)

func upgrade_rifle(stat):
	upgrade_weapon("rifle", stat)

func upgrade_shotgun(stat):
	upgrade_weapon("shotgun", stat)

func upgrade_melee(stat):
	upgrade_weapon("melee", stat)
	
func set_money(value):
	SoundManager.pickup.play()
	money += value

func update_gun_rotation():
	# Rotates the gun arrow according to the mouse position
	weaponsManager.look_at(get_global_mouse_position())
	pass

func update_bomb_indicator_rotation():
	var enemies = get_tree().get_nodes_in_group("Enemy")

	if enemies.size() == 0:
		bombIndicator.hide()
		return
		
	for enemy in enemies:
		if enemy.hasBomb:
			bombIndicator.look_at(enemy.global_position)
			bombIndicator.show()

func update_animation():
	flip_sprite()
	# Updates player animation based on velocity
	if velocity != Vector2.ZERO:
		anim.play("run")
	else:
		anim.play("idle")

func update_camera():
	if Input.is_action_pressed("ZoomIn"):
		playerCamera.zoomFactor += 0.01
	elif Input.is_action_pressed("ZoomOut"):
		playerCamera.zoomFactor -= 0.01
	else:
		playerCamera.zoomFactor = 1.0

func flip_sprite():
	# Flips the sprite depending on the mouse position
	if get_global_mouse_position().x < global_position.x:
		anim.flip_h = true
	elif get_global_mouse_position().x > global_position.x:
		anim.flip_h = false
		
func check_hit():
	if health <= 0:
		die.rpc()
	
@rpc("any_peer", "call_local")
func switch_weapon(index):	
	SoundManager.weaponSwitch.play()
	currentWeaponIndex = index
	currentWeapon.get_node("ArrowIndicator").texture = load(weaponsData[currentWeaponIndex].texture)
	currentWeapon.get_node("FireCooldown").wait_time = weaponsData[currentWeaponIndex].wait_time
	
@rpc("any_peer", "call_local")
func fire(held_down):
	if GameManager.gameOver: return 
	if held_down:
		weapon_held_down = true
	elif not held_down:
		weapon_held_down = false
	
	while weapon_held_down:
		if dead or GameManager.gameOver:
			break
		if currentWeapon.get_node("FireCooldown").is_stopped():
			SoundManager.gunSounds[currentWeaponIndex].play()
			dmgAdd = weaponUpgrades.values()[currentWeaponIndex]["damage"][2]

			if currentWeaponIndex != 3:
				accSub = weaponUpgrades.values()[currentWeaponIndex]["accuracy"][2]
				bulletSpeedAdd = weaponUpgrades.values()[currentWeaponIndex]["bulletSpeed"][2]

				var currentWeaponData = weaponsData[currentWeaponIndex]
				var multishot = currentWeaponData.multishot
				var deviation_angle = currentWeaponData.deviation_angle - accSub

				for i in range(multishot):
					if multiplayer.is_server():
						var bulletSpawner = get_tree().get_root().get_node("TestMultiplayerScene/BulletSpawner")
						var bulletSpawnPos = Vector2.ZERO
						
						if currentWeaponIndex == 0: # Pistol
							bulletSpawnPos = currentWeapon.get_node("BulletSpawn").global_position
						else: # Rifle and Shotgun
							bulletSpawnPos = currentWeapon.get_node("BulletSpawn2").global_position
						
						bulletSpawner.spawn([
							bulletSpawnPos,
							currentWeaponData.bullet_speed + bulletSpeedAdd, # bulletSpeed
							currentWeaponData.damage + dmgAdd, # Damage
							weaponsManager.rotation_degrees + randi_range(-deviation_angle, deviation_angle), # bullet rotation
							currentWeaponData.bullet_life
						])

				if currentWeaponIndex == 0:
					gunfire.global_position = currentWeapon.get_node("BulletSpawn").global_position
				else:
					gunfire.global_position = currentWeapon.get_node("BulletSpawn2").global_position
					
				gunfire.rotation_degrees = weaponsManager.rotation_degrees
				
				gunfire.emitting = true
				
			else:
				melee()
			
			currentWeapon.get_node("FireCooldown").start()
			
		await get_tree().create_timer(0.2).timeout
	

func melee():
	var currentWeaponData = weaponsData[currentWeaponIndex]
	currentWeapon.get_node("ArrowIndicator").visible = false
	meleeNode.visible = true
	meleeNode.dmg = currentWeaponData.damage + dmgAdd
	meleeNode.position = currentWeapon.get_node("BulletSpawn").position
	meleeNode.play_melee()

func finished_anim():
	currentWeapon.get_node("ArrowIndicator").visible = true
	meleeNode.visible = false

func handle_hit(dmg):
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id() and not showIframes:
		iFramesTimer.start()
		showIframes = true
		SoundManager.playerHit.play()
		health -= dmg
		update_hud.rpc()
	
@rpc("any_peer", "call_local")
func handle_boss_bullet(damage):
	handle_hit(damage)

func toggle_ready():
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		SoundManager.click.play()
		readyState = !readyState
		readyPrompt.update_ready_count()

@rpc("any_peer", "call_local")
func die():
	dead = true
	SoundManager.playerDeath.play()
	anim.play("death")
	collision.disabled = true

func _on_animated_sprite_2d_animation_finished():
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		start_respawn.rpc()

@rpc("any_peer", "call_local")
func start_respawn():
	respawn = true

func display_respawn():
	respawn = false
	respawnLabel.text = "Respawning In: %0.1fs" % respawnTimer.time_left

func _on_respawn_timer_timeout():
	if multiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		var root = get_tree().get_root()
		var playerSpawnPoint = root.get_node("TestMultiplayerScene/PlayerSpawnPoints")
		var spawnPoints = playerSpawnPoint.get_children()

		var randomIndex = randi_range(0, spawnPoints.size() - 1)
		var randomSpawnPoint = spawnPoints[randomIndex].position
		
		self.position = randomSpawnPoint
		
		dead = false
		respawnLabel.hide()
		respawnModal.hide()
		collision.disabled = false
		health = maxHealth
		update_hud.rpc()
		
		SoundManager.playerRespawn.play()


func _on_i_frames_timer_timeout():
	showIframes = false
	anim.set_self_modulate(Color(1, 1, 1, 1))
