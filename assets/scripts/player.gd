extends CharacterBody3D

@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_dash : bool = false
@export var can_freefly : bool = true

@export_group("Speeds")
@export var base_speed : float = 7.0
@export var freefly_speed : float = 30.0

@export_group("Trails")
@export var ghost : Node3D
@export var ghost_mat : StandardMaterial3D


var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var near_wall : bool = false
var was_near_wall : bool = false
var crouching : bool = false
var crouch_end_requested : bool = false
var downhill : bool = false
var is_switching : bool = false
var wall_running : bool = false


var move_velocity: Vector3
var jump_velocity: Vector3
var walj_velocity: Vector3
var wall_velocity: Vector3
var slide_velocity: Vector3
var dash_velocity: Vector3
var grapple_velocity: Vector3
var grav_velocity: Vector3
var external_velocity: Vector3
var kb_velocity: Vector3


var input_dir = 0.0
var move_dir = 0.0
var wall_normal: Vector3


var wall_run_speed = 0.0
var grapple_speed = 0.0 


var hp = 100
var dash_charges = 3
var jump_buffer: float = 0.0
var slide_buffer: float = 0.0
var dash_buffer: float = 0.0
var shoot_buffer: float = 0.0
var switch_buffer: float = 0.0
var hat_buffer: float = 0.0
var walj_lockout: float = 0.0
var iframe_timer: float = 0.0
var bounce_timer: float = 0.0
var sword_logging : bool = true


enum wpn { GUNS, SWORD }
var current_wpn = wpn.SWORD
var shoot_l : bool = false
var combo_step : int = 1
var trailing: bool = false


const hitfx = preload("res://assets/scenes/player/hitfx.tscn")


@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var hat: RigidBody3D = get_node("../Hat")

@onready var dash_cd: Timer = $Dash_CD
@onready var combo: Timer = %ComboTimer
@onready var hat_timer: Timer = $timers/HatNoYKillWindow
@onready var downhill_timer: Timer = $timers/DownhillEndWindow
@onready var dashjump_timer: Timer = $timers/DashJumpWindow
@onready var pistol_timeslow_timer: Timer = $timers/PistolSecondaryTimer

@onready var juice = $Head
@onready var hud: Control

@onready var wallcheck: ShapeCast3D = $WallChecker
@onready var wallcheck_r: RayCast3D = $WallCheckRight
@onready var wallcheck_l: RayCast3D = $WallCheckLeft
@onready var ceilingcheck: ShapeCast3D = $CeilingChecker

@onready var anim_gun: AnimationPlayer = %PistolPlayer
@onready var anim_sword = %SwordPlayer
@onready var sword_hitbox = %SwordHitbox
@onready var parry_hitbox = %ParryHitbox

@export var anim_funny: AnimationPlayer

@onready var guns: Node3D = %PistolsParent
@onready var sword: Node3D = %Sword

func _ready() -> void:
	
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	
	weapon_setup()
	
func _unhandled_input(event: InputEvent) -> void:
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	if can_freefly and Input.is_action_just_pressed("freefly"):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _process(delta: float) -> void:
	if trailing: 
		PhysUtil.ghost(ghost, ghost_mat, 0.05)


func _physics_process(delta: float) -> void:
	
	if can_freefly and freeflying:
		input_dir = Input.get_vector("left", "right", "forward", "back")
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	if Input.is_action_just_pressed("reset"): get_tree().reload_current_scene()
	
	input_dir = Input.get_vector("left", "right", "forward", "back")
	move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	near_wall = (wallcheck.is_colliding())
	
	if Input.is_action_just_pressed("jump"): jump_buffer = 0.2
	if jump_buffer > 0.0: jump_buffer -= delta
	
	if Input.is_action_just_pressed("slide"): slide_buffer = 0.5
	if slide_buffer > 0.0: slide_buffer -= delta
	
	if Input.is_action_just_pressed("dash"): dash_buffer = 0.2
	if dash_buffer > 0.0: dash_buffer -= delta
	
	if Input.is_action_just_pressed("switch_weapon"): switch_buffer = 0.5
	if switch_buffer > 0.0: switch_buffer -= delta
	
	if Input.is_action_just_pressed("hat_trick"): hat_buffer = 0.5
	if hat_buffer > 0.0: hat_buffer -= delta
	
	if shoot_buffer > 0.0:
		shoot_buffer -= delta
		deal_shot()
	
	if iframe_timer > 0.0: iframe_timer -= delta
	if walj_lockout > 0.0: walj_lockout -= delta
	if bounce_timer > 0.0: bounce_timer -= delta
	
	if sword_hitbox.monitoring: deal_swing()
	
	movestuff(delta)
	grav(delta)
	dash(delta)
	slide(delta)
	jump(delta)
	wall(delta)
	grapplestuff(delta)
	combatstuff(delta)
	
	velocity = move_velocity + jump_velocity + wall_velocity + walj_velocity + dash_velocity + slide_velocity + grapple_velocity + grav_velocity + external_velocity + kb_velocity

	move_and_slide()

	if wallcheck.is_colliding(): wall_normal = wallcheck.get_collision_normal(0)
	else: wall_normal = Vector3.ZERO
	#if is_on_wall() and wall_normal.length() > 0.1:
		#dash_velocity = Vector3.ZERO
		#slide_velocity = slide_velocity.slide(wall_normal)
		#grapple_velocity = grapple_velocity.slide(wall_normal) / 5
		#wall_velocity = wall_velocity.slide(wall_normal)

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * Settings.sens
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * Settings.sens
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.rotation.x = look_rotation.x


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func movestuff(delta) -> void:
	if walj_lockout > 0.0:
		move_velocity = Vector3.ZERO
		return
		
	if move_dir:
		base_speed = 5.0 if (not is_on_floor() and is_on_wall()) else 7.0
		
		move_velocity = move_velocity.move_toward(move_dir * base_speed, 50.0 * delta)
	else:
		var air_drag = 2.0 if not is_on_floor() else 100.0
		move_velocity = move_velocity.move_toward(Vector3.ZERO, air_drag * delta)
			
		if move_velocity.length_squared() < 0.01: move_velocity = Vector3.ZERO

func dash(delta) -> void:
	if dash_charges < 3 and dash_cd.is_stopped(): dash_cd.start()
	if dash_buffer > 0.0 and dash_charges > 0:
		dash_buffer = 0
		grav_velocity = Vector3.ZERO
		jump_velocity = Vector3.ZERO
		slide_velocity = Vector3.ZERO
		grapple_velocity = Vector3.ZERO
		wall_velocity = Vector3.ZERO
		dashjump_timer.start()
		var dash_dir = -head.global_transform.basis.z
		var dash_impulse = 100.0
		var cam_allowed = (input_dir.x == 0 and input_dir.y <= 0 and current_wpn == wpn.SWORD and dash_charges >= 2)
		if cam_allowed:
			dash_dir = -head.global_transform.basis.z
			dash_impulse = 170.0
		else:
			dash_dir = move_dir
			dash_impulse = 100.0 if is_on_floor() else 140.0
		dash_velocity = (dash_dir * dash_impulse)
		dash_charges -= 1 if not cam_allowed else 2
	var speed_ratio = clamp(dash_velocity.length() / 170.0, 0.0, 1.0)
	var decay = lerp(18.0, 1.0, speed_ratio)
	dash_velocity = dash_velocity * exp(-decay * delta)
	if dash_velocity.length_squared() < 1.0 or wall_run_speed > 10.0: dash_velocity = Vector3.ZERO

func slide(delta) -> void:
	if slide_buffer > 0.0 and is_on_floor():
		slide_buffer = 0.0
		crouch_start()
		var dir = move_dir if move_dir else -transform.basis.z
		var speed = maxf(20.0, Vector3(velocity.x, 0.0, velocity.z).length())
		var increment =  Vector3(slide_velocity.x, velocity.y * 5.0, slide_velocity.z).length() / 2.0
		slide_velocity = ((speed + increment) * dir).slide(get_floor_normal())
	else:
		if slide_velocity.length() > 0.0:
			var target_dir = -transform.basis.z if (not move_dir and is_on_floor()) else move_dir
			var current_dir = slide_velocity.normalized()
			var dir = current_dir.lerp(target_dir, 2.0 * delta)
			slide_velocity = dir * slide_velocity.length()
		
		var decay = 3.0
		
		var floor_normal = get_floor_normal()
		if floor_normal.length() > 0.1:
			var floor_angle = get_floor_angle()
			var true_down = Vector3.DOWN.slide(floor_normal).normalized()
			var slide_dir = slide_velocity.normalized()
			downhill = slide_dir.dot(true_down) > 0.3
			if is_on_floor() and floor_angle > 0.26 and downhill:
				var slope_accel = floor_angle * 150.0
				slide_velocity += slide_dir * (slope_accel * delta)
					
		if downhill:
			decay = 0.5
		elif not is_on_floor() and not is_on_wall() or near_wall:
			decay = 0.5
		else:
			decay = 4.0
		
		slide_velocity = slide_velocity * exp(-decay * delta)
		if slide_velocity.length_squared() < 4.0: slide_velocity = Vector3.ZERO
	if slide_velocity.length() <= 2.0:
		crouch_end()
	if crouch_end_requested: crouch_end()
	if !is_on_floor():
		if downhill_timer.is_stopped(): downhill_timer.start()
		await downhill_timer.timeout
		downhill = false

func jump(delta) -> void:
	if jump_buffer > 0.0 and (is_on_floor() or near_wall):
		grav_velocity.y = 0.0
		var jump_force = 14.0
		jump_buffer = 0.0
		
		if (wall_running or near_wall) and not is_on_floor():
			var flattened_wall = Vector3(wall_velocity.x, 0.0, wall_velocity.z).length()
			var launch_speed = clamp(flattened_wall * 1.1, 28.0, 42.0)
			var look_dir = -head.global_transform.basis.z
			var eject_dir = (wall_normal * 1.0 + look_dir * 1.2).normalized()
			#jump_velocity = (eject_dir * launch_speed) + Vector3(0.0, 12.0, 0.0)
			walj_velocity = eject_dir * launch_speed
			walj_velocity.y = 12.0
			
			#walj_lockout = 0.05
			#jump_velocity = Vector3(0.0, 12.0, 0.0)
			wall_velocity = Vector3.ZERO
			move_velocity = Vector3.ZERO
			wall_running = false
			return
		
		if slide_velocity.length() > 20.0:
			if downhill:
				jump_force += slide_velocity.length() * 0.4
				slide_velocity *= 0.6
			#else:
				#var slide_speed = slide_velocity.length()
				#if slide_speed <= 10.0:
					#jump_force = remap(slide_speed, 0.0, 10.0, 0.0, 12.0)
				#else:
					#jump_force = remap(slide_speed, 10.0, 25.0, 12.0, 14.0)
		
		elif !dashjump_timer.is_stopped():
			var launch_speed = 30.0
			var eject_dir = dash_velocity.normalized() + Vector3.UP
			wall_velocity = eject_dir * launch_speed
			dash_velocity.y = 0.0
			return
		
		jump_velocity.y = jump_force
		
		
	elif is_on_floor() or is_on_ceiling():
		jump_velocity = Vector3.ZERO
	else:
		jump_velocity = jump_velocity.move_toward(Vector3.ZERO, 25.0 * delta)

func wall(delta) -> void:
	
	var decay = 1.5 if !(is_on_floor() or is_on_wall()) else 5.0
	walj_velocity = walj_velocity * exp(-decay * delta)
	if walj_velocity.length_squared() < 0.01 or is_on_floor(): walj_velocity = Vector3.ZERO
	
	if near_wall and not is_on_floor() and move_dir.length() > 0.1 and wall_normal.length() > 0.1:
		var forward = -transform.basis.z
		if abs(forward.dot(wall_normal)) < 0.75:
			if not wall_running:
				var entry_dash = dash_velocity.limit_length(35.0)
				var incoming = move_velocity + jump_velocity + slide_velocity + entry_dash + grapple_velocity + external_velocity
				
				if incoming.length() < base_speed * 1.5:
					incoming = forward * (base_speed * 1.5)
				incoming = incoming
				
				wall_velocity = incoming.slide(wall_normal)
				
				jump_velocity = Vector3.ZERO
				grav_velocity = Vector3.ZERO
				dash_velocity = Vector3.ZERO
				
				slide_velocity = slide_velocity.slide(wall_normal) / 1.5
				grapple_velocity = grapple_velocity.slide(wall_normal) / 2
				
				wall_running = true

			var speed = wall_velocity.length()
			speed = move_toward(speed, base_speed * 1.2, 12.0 * delta)
			
			var wall_tangent = forward.slide(wall_normal).normalized()
			var current_dir = wall_velocity.normalized()
			var target_dir = current_dir.lerp(wall_tangent, 4.0 * delta).normalized()
			
			wall_velocity = target_dir * speed
			
			wall_velocity += (get_gravity() * 0.2) * delta
			return

	if wall_running:
		wall_running = false
		move_velocity = wall_velocity
		wall_velocity = Vector3.ZERO
	else:
		wall_velocity = wall_velocity.lerp(Vector3.ZERO, 15.0 * delta)


func grav(delta) -> void:
	var rising = jump_velocity.y > 4.0
	if not is_on_floor() and not near_wall and not rising and dash_velocity.length() <= 5.0 :
		grav_velocity += get_gravity() * delta
		grav_velocity *= pow(1.2, delta)
		was_near_wall = false
	elif near_wall and wall_velocity.length() < 5.0:
		if not was_near_wall:
			if grav_velocity.y < -2.0:
				grav_velocity.y = -2.0
				was_near_wall = true
		grav_velocity += get_gravity() / 20 * delta
		

	else:
		grav_velocity = Vector3.ZERO


func crouch_start() -> void:
	crouch_end_requested = false
	crouching = true
	collider.shape.height = 0.9
	collider.position.y = 0.45

func crouch_end() -> void:
	if ceilingcheck.is_colliding():
		crouch_end_requested = true
	else:
		crouching = false
		collider.shape.height = 1.8
		collider.position.y = 0.9
		crouch_end_requested = false


func grapplestuff(delta) -> void:
	if Input.is_action_pressed("taunt") and anim_funny.current_animation != "pointhold":
		anim_funny.play("fuhyu")
	
	if Input.is_action_just_released("grapple") and (anim_funny.current_animation == "pointhold" or anim_funny.current_animation == "pointstart"):
		anim_funny.play("pointend")
	
	if Input.is_action_pressed("grapple"):
		hat_timer.start()
		var target = PhysUtil.raycast_from_cam(%Camera3D, 200.0, [get_rid()], Vector3.ZERO, true, 4)
		if target and (target.position - global_position).length() > 5.0:
			grav_velocity = Vector3.ZERO
			external_velocity = Vector3.ZERO
			var point = target.collider
			if point.is_in_group("grapple"):
				if grapple_speed >= 0.0: hat_timer.start()
				
				var dist = target.position - global_position
				grapple_speed = dist.length()
				grapple_velocity = dist.normalized() * 40.0
				if anim_funny.current_animation != "pointstart" and anim_funny.current_animation != "pointhold": anim_funny.play("pointstart")
			else:
				anim_funny.play("pointend")
		
	else:
		
		var decay = 8.0
		if !is_on_floor(): decay = 1.0
		else: decay = 8.0
		grapple_velocity *= exp(-decay * delta)
		grapple_speed *= exp(-decay * delta)
		
		if grapple_velocity.length_squared() < 0.5: grapple_velocity = Vector3.ZERO
		if is_on_floor() and abs(grapple_velocity.y) >= 0.0 and hat_timer.time_left <= 0.0: grapple_velocity.y = 0
		
	#if Input.is_action_just_pressed("r") and hat.can_use:
		#match hat.current_state:
			#
			#hat.state.EQUIPPED:
				#juice.shift(1.7, 70, 0.2)
				#await get_tree().create_timer(0.2).timeout
				#var facing = -$Head/CameraPivot/Camera3D.global_transform.basis.z
				#var speed = 30.0 + velocity.length()
				#hat.launch(facing, speed)
			#
			#hat.state.LAUNCHED:
				#if not hat.used: hat_timer.start()
				#grav_velocity.y /= 5
				#hat.used = true
				#var pull_dir: Vector3 = (hat.global_position - global_position).normalized()
				#hat_velocity = pull_dir * 35.0
		#
			#hat.state.LANDED:
				#if not hat.used:
					#juice.shift(1.7, 60, 0.4)
					#await get_tree().create_timer(0.4).timeout
					#global_position = hat.global_position + Vector3(0, 1.0, 0)
					#hat.reset()
					#juice.shift(1.7, 110, 0.1)

func combatstuff(delta) -> void:
	
	external_velocity = external_velocity.move_toward(Vector3.ZERO, 4.0 * delta)
	if external_velocity.length_squared() < 0.5 or (is_on_floor() and bounce_timer <= 0.0): external_velocity = Vector3.ZERO
	kb_velocity = kb_velocity.lerp(Vector3.ZERO, 4.0 * delta)
	if kb_velocity.length_squared() < 0.5: kb_velocity = Vector3.ZERO
	
	if hat_buffer > 0.0 and hat.current_state == hat.state.EQUIPPED:
		var facing = -$Head/CameraPivot/Camera3D.global_transform.basis.z
		hat.launch(facing, 35.0, 0.5)
	
	if switch_buffer > 0.0 and not is_switching:
		switch_buffer = 0.0
		
		is_switching = true
		combo_step = 0
		shoot_buffer = 0.0
		anim_sword.stop()
		anim_gun.stop()
		combo.stop()
		
		match current_wpn:
			wpn.GUNS:
				anim_gun.play("drop")
				await anim_gun.animation_finished

				sword.visible = true
				anim_sword.play("ready")
				guns.visible = false
				current_wpn = wpn.SWORD
			wpn.SWORD:
				anim_sword.play("drop")
				await anim_sword.animation_finished
				
				guns.visible = true
				anim_gun.play("ready")
				sword.visible = false
				current_wpn = wpn.GUNS
		is_switching = false
		return
	
	match current_wpn:
		wpn.GUNS:
			if Input.is_action_pressed("primary") and !is_switching:
				if !anim_gun.is_playing():
					if shoot_l: anim_gun.play("L_shoot")
					else: anim_gun.play("R_shoot")
					hud.hit_time = 0.2
					shoot_l = !shoot_l
					shoot_buffer = 0.05
					return
				
			
			if Input.is_action_pressed("secondary") and !is_switching and pistol_timeslow_timer.time_left <= 0.0:
				juice.shift(999.0, 5, 1.0)
				PhysUtil.undulate(0.25, 1.0)
				pistol_timeslow_timer.start()
			elif Input.is_action_just_released("secondary"):
				Engine.time_scale = 1.0
				juice.shiftend()
				
			
		wpn.SWORD:
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


func hit(hit_data: Dictionary) -> void:
	if iframe_timer > 0.0: return
	
	hp -= hit_data["damage"]
	var modifier = 1.0 if is_on_floor() else 2.0
	kb_velocity += hit_data["dir"] * hit_data["knockback"] * modifier
	iframe_timer = 0.15
	
	var trauma = hit_data["damage"] / 50.0
	juice.add_trauma(trauma)

func kb_add(kb: float, dir: Vector3) -> void:
	external_velocity += kb * dir
	juice.add_trauma(0.1)
	bounce_timer = 0.5

func deal_shot() -> void:
	shoot_buffer = 0.0
	var cam = %Camera3D
	
	var offsets = [
		Vector3.ZERO,
		cam.global_transform.basis.x * 0.35, cam.global_transform.basis.x * -0.35,
		cam.global_transform.basis.y * 0.35, cam.global_transform.basis.y * -0.35
	]
	for offset in offsets:
		var result = PhysUtil.raycast_from_cam(%Camera3D, 1000.0, [get_rid()], offset)
		if result:
			var body = result.collider
			if body and body.has_method("hit"):
				var fx = hitfx.instantiate()
				body.add_child(fx)
				fx.global_position = result.position.lerp(body.global_position + (-body.transform.basis.z * 2), 0.2)
				fx.anim = "pistol"
				
				var hit_data = {
					"damage": 2.5, # replace with function bichazz
					"type": "GUN",
					"knockback": 0.0,
					"dir": -global_transform.basis.z
				}
				body.hit(hit_data)
				break

func deal_swing() -> void:
	for proj in parry_hitbox.get_overlapping_areas():
		if proj.is_in_group("projectile") and proj.parriable:
			trailing = true
			var angle = -%Camera3D.global_transform.basis.z
			proj.deflect(angle)
			var trauma = proj.hit_data["damage"] / 100.0
			juice.add_trauma(trauma)
			var hitstop_time = trauma / 2
			PhysUtil.hitstop(hitstop_time)
	
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

func weapon_setup() -> void:
	match current_wpn:
		wpn.SWORD:
			guns.visible = false
			sword.visible = true
			anim_sword.play("ready")
			combo_step = 0
		wpn.GUNS:
			sword.visible = false
			guns.visible = true
			anim_gun.play("ready")

func _on_dash_cd_timeout() -> void:
	if dash_charges < 3: dash_charges += 1

func _on_combo_timer_timeout() -> void:
	combo_step = 0
	anim_sword.play("sheath", 0.15)

func _on_sword_player_animation_finished(anim_name: StringName) -> void:
	trailing = false
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


func grapple_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"pointstart":
			anim_funny.play("pointhold")
		_:
			anim_funny.play("idle")
