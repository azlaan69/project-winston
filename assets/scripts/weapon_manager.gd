extends Node3D

enum wpn { SWORD, PISTOL }

var current_wpn := wpn.SWORD
var is_switching := false
var is_parrying := false
var combo_step := 0

var hat_buffer := 0.0
var switch_buffer := 0.0
var shoot_buffer := 0.0

@onready var hat: RigidBody3D
@onready var player = get_parent()

@export var camera: Camera3D
@export var juice: Node3D

@export var pistol: Node3D
@export var sword: Node3D
@export var marker_pistol: Marker3D
@export var anim_pistol: AnimationPlayer
@export var anim_sword: AnimationPlayer

@export var ghost: Node3D
@export var ghost_mat: Material

@export var shoot_fx: AudioStream
@export var tracerP: PackedScene
@export var hitfx: PackedScene

@export var sword_hitbox: Area3D
@export var parry_hitbox: Area3D

@export var combo: Timer
@export var pistol_timeslow_timer: Timer

func _ready() -> void:
	hat = get_tree().get_first_node_in_group("hat")
	weapon_setup()

func _physics_process(delta: float) -> void:
	
	hat_buffer = maxf(0.0, hat_buffer - delta)
	switch_buffer = maxf(0.0, switch_buffer - delta)
	shoot_buffer = maxf(0.0, shoot_buffer - delta)
	
	if Input.is_action_just_pressed("hat_trick"): hat_buffer = 0.5
	if Input.is_action_just_pressed("switch_weapon"): switch_buffer = 0.5
	if shoot_buffer > 0.0: deal_shot()
	if sword_hitbox.monitoring: deal_swing()
	if is_parrying: deal_parry()
	
	if hat_buffer > 0.0: action_hat()
	
	if switch_buffer > 0.0 and not is_switching:
		switch()
	
	match current_wpn:
		wpn.PISTOL:
			pistol_process()
				
		wpn.SWORD:
			sword_process()


func action_hat() -> void:
	var facing = -camera.global_transform.basis.z
	if hat.current_state == hat.state.EQUIPPED and hat.can_use:
		hat.launch(facing, 35.0, 1.0)
		hat_buffer = 0.0
	elif hat.current_state == hat.state.LAUNCHED or hat.current_state == hat.state.LANDED:
		hat.rebound()
		hat_buffer = 0.0

func switch() -> void:
	switch_buffer = 0.0
	
	is_switching = true
	combo_step = 0
	shoot_buffer = 0.0
	anim_sword.stop()
	anim_pistol.stop()
	combo.stop()
	
	match current_wpn:
		wpn.PISTOL:
			anim_pistol.play("throw")
			await anim_pistol.animation_finished

			sword.visible = true
			anim_sword.play("ready")
			pistol.visible = false
			current_wpn = wpn.SWORD
		wpn.SWORD:
			anim_sword.play("drop")
			await anim_sword.animation_finished
			
			pistol.visible = true
			anim_pistol.play("pullout")
			sword.visible = false
			current_wpn = wpn.PISTOL
	
	is_switching = false

func pistol_process() -> void:
	if Input.is_action_pressed("primary") and !is_switching:
		if anim_pistol.current_animation != "shoot":
			anim_pistol.play("shoot")
			player.play_sfx(shoot_fx, true)
			
			var tracer = tracerP.instantiate()
			get_parent().add_child(tracer)
			var start = marker_pistol.global_position
			var end = %Camera3D.global_position + (-%Camera3D.global_transform.basis.z * 100.0)
			tracer.init(start, end)

			shoot_buffer = 0.05
			
	if Input.is_action_pressed("secondary") and !is_switching and pistol_timeslow_timer.time_left <= 0.0:
		
		juice.shift(999.0, 5, 0.5)
		PhysUtil.undulate(0.25, 0.5)
		pistol_timeslow_timer.start()
		
	elif Input.is_action_just_released("secondary"):
		
		Engine.time_scale = 1.0
		juice.shiftend()

func sword_process() -> void:
	if Input.is_action_just_pressed("primary") and !is_switching:
		combo.stop()
		match combo_step:
			0:
				anim_sword.play("swing1")
			1:
				anim_sword.play("swing2")
			2:
				anim_sword.play("swing3")
			3:
				pass
	
	elif Input.is_action_just_pressed("secondary") and !is_switching:
		anim_sword.stop()
		combo.stop()
		anim_sword.play("parry")


func deal_shot() -> void:
	shoot_buffer = 0.0
	var cam = %Camera3D
	
	var offsets = [
		Vector3.ZERO,
		cam.global_transform.basis.x * 0.35, cam.global_transform.basis.x * -0.35,
		cam.global_transform.basis.y * 0.35, cam.global_transform.basis.y * -0.35
	]
	for offset in offsets:
		var result = PhysUtil.raycast_from_cam(%Camera3D, 1000.0, [player.get_rid()], offset)
		if result:
			
			var body = result.collider
			if body and body.has_method("hit"):
				var fx = hitfx.instantiate()
				body.add_child(fx)
				fx.global_position = result.position.lerp(body.global_position + (-body.transform.basis.z * 2), 0.2)
				fx.anim = "pistol"
				
				var hit_data = {
					"damage": 2.5,
					"type": "GUN",
					"knockback": 0.0,
					"dir": -camera.global_transform.basis.z
				}
				body.hit(hit_data)
				break

func deal_swing() -> void:
	
	for body in sword_hitbox.get_overlapping_bodies():
		
		if body != self and body.has_method("hit") and not body.iframe_timer > 0.0:
			var fx = hitfx.instantiate()
			body.add_child(fx)
			fx.global_position = body.global_position + (-body.transform.basis.z * 1.0)
			fx.anim = "sword"
			
			var hit_data = {
				"damage": 5.0,
				"type": "SWORD",
				"knockback": 10.0,
				"dir": -global_transform.basis.z
			}
			body.hit(hit_data)

func deal_parry() -> void:
	var targets = parry_hitbox.get_overlapping_areas() + parry_hitbox.get_overlapping_bodies()
	var trauma = 0
	for proj in targets:
		if proj.is_in_group("projectile") and proj.parriable:
			var angle = -camera.global_transform.basis.z
			proj.deflect(angle)
			anim_sword.play("sheath", 0.1)
			trauma = proj.hit_data["damage"] / 70.0
			parry_connect(trauma)
		
		if proj.is_in_group("hat") and (hat.current_state == hat.state.RETURN or hat.current_state == hat.state.LAUNCHED):
			var facing = -camera.global_transform.basis.z
			hat.deflect(facing)
			trauma = 0.01
			parry_connect(trauma)
			
		

func parry_connect(trauma) -> void:
	PhysUtil.ghost(ghost, ghost_mat, 0.05)
	juice.add_trauma(trauma)
	var hitstop_time = maxf(0.1, trauma / 2)
	PhysUtil.hitstop(hitstop_time)

func weapon_setup() -> void:
	match current_wpn:
		wpn.SWORD:
			pistol.visible = false
			sword.visible = true
			anim_sword.play("ready")
			combo_step = 0
		wpn.PISTOL:
			sword.visible = false
			pistol.visible = true
			anim_pistol.play("ready")

func parry_state(yes: bool = false) -> void:
	is_parrying = yes



func _on_combo_timer_timeout() -> void:
	combo_step = 0
	anim_sword.play("sheath", 0.15)

func _on_sword_player_animation_finished(anim_name: StringName) -> void:
	player.trailing = false
	match anim_name:
		"swing1":
			combo_step = 1
			combo.start(0.6)
		"swing2":
			combo_step = 2
			combo.start(0.6)
		"swing3":
			combo_step = 0
			combo.start(0.3)
		"sheath":
			combo_step = 0
