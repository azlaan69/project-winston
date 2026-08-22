extends Control

@onready var dash_meter = $DashHud/DashMeter

@export var player: CharacterBody3D
# Called when the node enters the scene tree for the first time.
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

	$HatHud/Equipped.visible = (player.hat.current_state == player.hat.state.EQUIPPED and player.hat.can_use)
	$HatHud/Launched.visible = (player.hat.current_state == player.hat.state.LAUNCHED and player.hat.can_use)
	$HatHud/Landed.visible = (player.hat.current_state == player.hat.state.LANDED and player.hat.can_use)
	$HatHud/CD.visible = (not player.hat.can_use)

	$HatHud/HatBG/CD.value = 1.0 - (player.hat.cd.time_left / player.hat.cd.wait_time)
