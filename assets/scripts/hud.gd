extends Control

@onready var dash_meter = $DashHud/DashMeter
@export var player: CharacterBody3D

var speed: float = 0.0
var hit_time: float = 0.0

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dash_charges = player.dash_charges
	var time_left = player.dash_cd.time_left
	var total_time = player.dash_cd.wait_time
	
	for i in range(3):
		var bar = dash_meter.get_child(i)
		
		if i < dash_charges: bar.value = 1.0
		elif i == dash_charges: 
			if player.dash_cd.is_stopped(): bar.value = 0.0
			else: bar.value = 1.0 - (time_left / total_time)
		else: bar.value = 0.0
	
	$HealthHud/TextureProgressBar.value = (player.hp / 100)
	
	speed = lerp(speed, player.velocity.length(), 6.0 * delta)
	
	if hit_time > 0.0: hit_time -= delta
	
	$HatHud/Equipped.visible = (player.hat.current_state == player.hat.state.EQUIPPED and player.hat.can_use)
	$HatHud/Launched.visible = (player.hat.current_state == player.hat.state.LAUNCHED and player.hat.can_use)
	$HatHud/Landed.visible = (player.hat.current_state == player.hat.state.LANDED and player.hat.can_use)
	$HatHud/CD.visible = (not player.hat.can_use)

	$HatHud/HatBG/CD.value = 1.0 - (player.hat.cd.time_left / player.hat.cd.wait_time)
	$SpeedText.text = str(int(round(speed)))

	$Trails/Left/one.visible = (!player.shoot_l and hit_time > 0.15 and hit_time <= 0.2)
	$Trails/Left/two.visible = (!player.shoot_l and hit_time > 0.0 and hit_time <= 0.15)
	$Trails/Right/one.visible = (player.shoot_l and hit_time > 0.15 and hit_time <= 0.2)
	$Trails/Right/two.visible = (player.shoot_l and hit_time > 0.0 and hit_time <= 0.15)

	var local_vel := player.transform.basis.inverse() * -player.velocity * (1.0 if player.is_on_floor() else 0.5)
	$Crosshair.rotation = lerp($Crosshair.rotation, local_vel.normalized().x * 0.5, 8.0 * delta)
	var crosshair_ypos = 540.0 
	if player.crouching and player.is_on_floor(): crosshair_ypos = 550.0
	$Crosshair.position.y = lerp($Crosshair.position.y, crosshair_ypos, 4.0 * delta)
	
	$Crosshair/Gun.visible = (player.current_wpn == player.wpn.GUNS)
	$Crosshair/Sword.visible = (!$Crosshair/Gun.visible)
