extends CharacterBody3D

@export_group("actuallyneedts_weapons")
@export var pistol: Node3D

@export_group("actuallyneedts_anim")
@export var anim_funny: AnimationPlayer
@export var anim_katana: AnimationPlayer
@export var anim_pistol: AnimationPlayer
@export var marker_pistol: Marker3D
@export var grapple_rope: Node3D
@export var can_freefly : bool = true

@export_group("audio")
@export var sfx: AudioStreamPlayer3D
@export var shoot_fx: AudioStream
@export var hat_reload_fx: AudioStream
@export var katana_swing_fx: AudioStream

@export_group("components")
@export var wpn_manager: Node3D

var use_new_controller: bool = true

enum state { WALKING, SLIDING, AIRBORNE, WALL, GRAPPLING }
var current_state = state.AIRBORNE
var last_state = state.AIRBORNE

var fall_time := 0.0
var slide_add_limit = 10.0


var base_speed : float = 7.0
var freefly_speed : float = 30.0

var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var near_wall : bool = false
var was_near_wall : bool = false
var crouching : bool = false
var crouch_end_requested : bool = false
var downhill : bool = false
var is_switching : bool = false
var is_parrying : bool = false
var wall_running : bool = false
var grappling : bool = false
var grap_scale : float = 0.0


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
var grap_pos: Vector3
var grap_node: Node3D


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
var slide_cooldown: float = 0.0
var sword_logging : bool = true


enum wpn { GUNS, SWORD }
var current_wpn = wpn.SWORD
var shoot_l : bool = true
var combo_step : int = 1
var trailing: bool = false


const hitfx = preload("res://assets/scenes/player/hitfx.tscn")
const tracerP = preload("res://assets/scenes/player/tracer_pistol.tscn")


@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var hat: RigidBody3D = get_node("../Hat")

@onready var dash_cd: Timer = %Dash_CD
@onready var hat_timer: Timer = %HatNoYKillWindow
@onready var downhill_timer: Timer = %DownhillEndWindow
@onready var dashjump_timer: Timer = %DashJumpWindow

@onready var juice = $Head
@onready var hud: Control

@onready var wallcheck: ShapeCast3D = %WallChecker
@onready var wallcheck_r: RayCast3D = %WallCheckRight
@onready var wallcheck_l: RayCast3D = %WallCheckLeft
@onready var ceilingcheck: ShapeCast3D = %CeilingChecker


@onready var outline_filter = %Filter

func _ready() -> void:
	
	var current_method = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	var is_gl = (current_method == "gl_compatibility")
	
	outline_filter.visible = !is_gl
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	
func _unhandled_input(event: InputEvent) -> void:
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	if can_freefly and Input.is_action_just_pressed("freefly"):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		use_new_controller = !use_new_controller


func _physics_process(delta: float) -> void:
	
	if can_freefly and freeflying:
		input_dir = Input.get_vector("left", "right", "forward", "back")
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	if Input.is_action_just_pressed("reset"): get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed("jump"): jump_buffer = 0.2
	if Input.is_action_just_pressed("slide"): slide_buffer = 0.5
	if Input.is_action_just_pressed("dash"): dash_buffer = 0.2
	
	jump_buffer = maxf(0.0, jump_buffer - delta)
	slide_buffer = maxf(0.0, slide_buffer - delta)
	dash_buffer = maxf(0.0, dash_buffer - delta)
	
	if use_new_controller:
		input_dir = Input.get_vector("left", "right", "forward", "back")
		move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		match current_state:
			state.WALKING:
				walk_process(delta)
			state.SLIDING:
				slide_process(delta)
			state.AIRBORNE:
				air_process(delta)
			state.WALL:
				wall_process(delta)
			state.GRAPPLING:
				grapple_process(delta)
		
		move_and_slide()
		
	else:
		
		input_dir = Input.get_vector("left", "right", "forward", "back")
		move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		near_wall = (wallcheck.is_colliding() or is_on_wall())
		
		
		slide_cooldown = maxf(0.0, slide_cooldown - delta)
		
		if iframe_timer > 0.0: iframe_timer -= delta
		if walj_lockout > 0.0: walj_lockout -= delta
		if bounce_timer > 0.0: bounce_timer -= delta
		
		
		
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
	

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * Settings.sens
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-89), deg_to_rad(89))
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

func change_state(new_state) -> void:
	if new_state == current_state: return
	
	last_state = current_state
	current_state = new_state
	
	crouch_end()
	
	match current_state:
		state.SLIDING:
			enter_slide()
		state.AIRBORNE:
			fall_time = 0.0

func walk_process(delta) -> void:
	var walk_speed = 7.0
	var accel = 90.0
	var friction = 50.0 if (last_state == state.SLIDING or last_state == state.AIRBORNE) else 70.0
	
	if move_dir.length_squared() > 0.0:
		var target_vel = move_dir * walk_speed
		velocity.x = move_toward(velocity.x, target_vel.x, accel * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, accel * delta)
	
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	
	if slide_buffer > 0.0:
		slide_buffer = 0.0
		change_state(state.SLIDING)
		return
	
	if jump_buffer > 0.0:
		jump_buffer = 0.0
		velocity.y = 12.0
		change_state(state.AIRBORNE)
		return
	
	if not is_on_floor():
		change_state(state.AIRBORNE)
		return

func slide_process(delta) -> void:
	var floor_normal = get_floor_normal()
	var slope_dot = velocity.normalized().dot(floor_normal)
	
	if slope_dot > 0.1:
		velocity += velocity.normalized() * 35.0 * delta
	else:
		
		var decay = 2.0
		var h_vel = Vector2(velocity.x, velocity.z)
		h_vel *= exp(-decay * delta)
		
		velocity.x = h_vel.x
		velocity.z = h_vel.y
		
	if jump_buffer > 0.0 and is_on_floor():
		
		jump_buffer = 0.0
		
		var h_vel = Vector2(velocity.x, velocity.z)
		var h_speed = h_vel.length()
		var h_dir = h_vel / h_speed
		var capped_speed = minf(h_speed + 2.0, 30.0)
		
		velocity.x = capped_speed * h_dir.x
		velocity.z = capped_speed * h_dir.y 
		
		velocity.y = remap(capped_speed, 0.0, 30.0, 2.0, 11.0)
	
		change_state(state.AIRBORNE)
		return
	
	var hspeed = Vector3(velocity.x, 0.0, velocity.z).length()
	if hspeed < 8.0:
		change_state(state.WALKING)
		return
	
	if not is_on_floor():
		change_state(state.AIRBORNE)
		return

func air_process(delta) -> void:
	
	fall_time += delta
	var gravity = 14.0 * pow(1.7, fall_time)
	velocity.y -= gravity * delta
	
	var h_vel = Vector2(velocity.x, velocity.z)
	var current_hspeed = h_vel.length()
	
	if move_dir.length_squared() > 0.0:
		if last_state == state.SLIDING:
			if abs(move_dir.dot(velocity.normalized())) < 0.6:
				var target_h_dir = Vector2(move_dir.x, move_dir.z).normalized()
				
				if current_hspeed > 0.0:
					var current_h_dir = h_vel / current_hspeed
					var factor = 1.0
					var new_h_dir = current_h_dir.slerp(target_h_dir, factor * delta)
					h_vel = new_h_dir * current_hspeed
		
		else:
			var air_accel = 40.0
			var air_cap = 12.0
			
			var target_h_vel = Vector2(move_dir.x, move_dir.z).normalized() * air_cap
			h_vel = h_vel.move_toward(target_h_vel, air_accel * delta)
			
			
	var air_drag = 0.2 if last_state == state.SLIDING else 0.05
	h_vel *= exp(-air_drag * delta)
	velocity.x = h_vel.x
	velocity.z = h_vel.y

		
	if is_on_floor():
		change_state(state.WALKING)
		return

func wall_process(delta) -> void:
	pass

func grapple_process(delta) -> void:
	pass

func enter_slide() -> void:
	var slide_dir = move_dir if move_dir != Vector3.ZERO else -transform.basis.z
	var current_hspeed = Vector3(velocity.x, 0.0, velocity.z).length()
	var launch_speed = current_hspeed + maxf(12.0, current_hspeed * 0.2)
	
	velocity.x = slide_dir.x * launch_speed
	velocity.z = slide_dir.z * launch_speed
	crouch_start()


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
		iframe_timer = 0.2
		dashjump_timer.start()
		var dash_dir = -head.global_transform.basis.z
		var dash_impulse = 100.0
		var cam_allowed = (input_dir.x == 0 and input_dir.y <= 0 and current_wpn == wpn.SWORD and dash_charges >= 2)
		if cam_allowed:
			dash_dir = -head.global_transform.basis.z
			dash_impulse = 170.0
		else:
			dash_dir = move_dir if move_dir else -transform.basis.z
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
		var increment = 0.0
		
		if slide_cooldown <= 0.0:
			increment =  Vector3(slide_velocity.x, velocity.y * 5.0, slide_velocity.z).length() / 2.0
			slide_cooldown = 2.0
			
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
			
			var facing_down = -transform.basis.z.dot(true_down) > 0.1
			
			downhill = is_on_floor() and facing_down and slide_dir.dot(true_down) > 0.3 and floor_angle > 0.26  
			if downhill:
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
		slide_cooldown = 0.0
		
		if (wall_running or near_wall) and not is_on_floor():
			
			var current_vel = Vector3(velocity.x, 0, velocity.z).length()
			var flattened_wall = Vector3(wall_velocity.x, 0.0, wall_velocity.z).length()
			var launch_speed = clamp(maxf(flattened_wall, current_vel) * 1.5, 30.0, 50.0)
			var look_dir = -head.global_transform.basis.z
			var eject_dir = (wall_normal * 1.0 + look_dir * 1.2 + Vector3.UP * 0.6).normalized()
			walj_velocity = eject_dir * launch_speed
			walj_velocity.y = 12.0

			wall_velocity = Vector3.ZERO
			move_velocity = Vector3.ZERO
			wall_running = false
			return
		
		if slide_velocity.length() > 40.0:
			if downhill:
				jump_force += slide_velocity.length() * 0.4
				slide_velocity *= 0.6
		
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
	
	if near_wall and (not is_on_floor()) and move_dir.length() > 0.1 and wall_normal.length() > 0.1:
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
			jump_velocity = Vector3.ZERO
			grav_velocity = Vector3.ZERO
			dash_velocity = Vector3.ZERO
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
		grav_velocity += (get_gravity() * 1.1) * delta
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
	var scale_factor = 20.0 if grappling else 50.0
	grapple_rope.scale = grapple_rope.scale.move_toward(Vector3(1, 1, grap_scale), scale_factor * delta)
	grapple_rope.visible = (grapple_rope.scale != Vector3(1, 1, 0))
	
	if Input.is_action_pressed("taunt") and anim_funny.current_animation != "pointhold":
		anim_funny.play("fuhyu")
	
	if Input.is_action_just_pressed("grapple"):
		if grappling:
			grap_stop()
		else:
			grap_start()
	if grappling and Input.is_action_just_pressed("jump"): grap_stop()
	
	if grappling:
		if is_instance_valid(grap_node):
			grap_pos = grap_node.global_position
		
		var dist_vec := grap_pos - global_position
		var dist = dist_vec.length()
		if dist < 10.0: 
			grap_stop()
		else:
			grav_velocity = Vector3.ZERO
			external_velocity = Vector3.ZERO
			if grapple_velocity.length() >= 0.0: hat_timer.start()
			
			grapple_speed = dist
			grapple_velocity = dist_vec.normalized() * 40.0
			grappling = true
			grapple_rope.look_at(grap_pos - Vector3(0, 0.5, 0))
			grap_scale = dist
			if anim_funny.current_animation != "pointstart" and anim_funny.current_animation != "pointhold": anim_funny.play("pointstart")
	else:
		
		grap_scale = 0.0
		var decay = 8.0
		if !is_on_floor(): decay = 1.0
		else: decay = 8.0
		grapple_velocity *= exp(-decay * delta)
		grapple_speed *= exp(-decay * delta)
		
		if grapple_velocity.length_squared() < 0.5: grapple_velocity = Vector3.ZERO
		if is_on_floor() and abs(grapple_velocity.y) >= 0.0 and hat_timer.time_left <= 0.0: grapple_velocity.y = 0

func grap_start() -> void:
	var target = PhysUtil.raycast_from_cam(%Camera3D, 200.0, [get_rid()], Vector3.ZERO, true, 4)
	if target and (target.collider.global_position - global_position).length() > 10.0:
		print(target.collider)
		if target.collider.is_in_group("grapple"):
			grappling = true
			grap_pos = target.position
			grap_node = target.collider
			return
	
	grap_stop()

func grap_stop() -> void:
	grappling = false
	grap_node = null
	grap_scale = 0.0
	if (anim_funny.current_animation == "pointhold" or anim_funny.current_animation == "pointstart"): anim_funny.play("pointend")

func combatstuff(delta) -> void:
	
	external_velocity = external_velocity.move_toward(Vector3.ZERO, 4.0 * delta)
	if external_velocity.length_squared() < 0.5 or (is_on_floor() and bounce_timer <= 0.0): external_velocity = Vector3.ZERO
	kb_velocity = kb_velocity.lerp(Vector3.ZERO, 4.0 * delta)
	if kb_velocity.length_squared() < 0.5: kb_velocity = Vector3.ZERO
	
func play_sfx(stream: AudioStream, do_random: bool = true) -> void:
	sfx.stream = stream
	if do_random == true:
		sfx.pitch_scale = randf_range(0.8, 1.3)
		sfx.volume_db = randf_range(-5.0, 2.0)
	sfx.play()

func play_swing_fx_helper() -> void:
	play_sfx(katana_swing_fx)

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
	grav_velocity = Vector3.ZERO

func parry_state(yes: bool = false) -> void:
	wpn_manager.parry_state(yes)

func _on_dash_cd_timeout() -> void:
	if dash_charges < 3: dash_charges += 1

func grapple_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"pointstart":
			anim_funny.play("pointhold")
		_:
			anim_funny.play("idle")
