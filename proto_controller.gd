extends CharacterBody3D

@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_dash : bool = false
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_speed : float = 6.0
@export var dash_speed : float = 20.0
@export var freefly_speed : float = 25.0
@export var slide_speed : float = 10.0

@export_group("Input Actions")
@export var input_left : String = "a"
@export var input_right : String = "d"
@export var input_forward : String = "w"
@export var input_back : String = "s"
@export var input_jump : String = "space"
@export var input_dash : String = "shift"
@export var input_freefly : String = "freefly"
@export var input_slide : String = "ctrl"
@export var input_attack : String = "lmb"
@export var input_secondary : String = "rmb"
@export var input_switch : String = "q"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var near_wall : bool = false
var was_near_wall : bool = false
var crouching : bool = false
var crouch_end_requested : bool = false
var downhill : bool = false

var move_velocity: Vector3
var jump_velocity: Vector3
var slide_velocity: Vector3
var dash_velocity: Vector3
var external_velocity: Vector3
var grav_velocity: Vector3

var input_dir = 0.0
var move_dir = 0.0

var dash_charges = 3
var jump_buffer: float = 0.0
var slide_buffer: float = 0.0
var dash_buffer: float = 0.0
var shoot_buffer: float = 0.0

enum wpn { GUNS, SWORD }
var current_wpn = wpn.SWORD
var shoot_l : bool = false
var combo_step : int = 1

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var debug: Label = $Overlay/HUD/Label
@onready var hat: RigidBody3D = get_node("../Hat")

@onready var dash_cd: Timer = $Dash_CD
@onready var combo: Timer = $Head/CameraPivot/SubViewportContainer/SubViewport/ComboTimer

@onready var juice = $Head

@onready var wallcheck: ShapeCast3D = $WallChecker
@onready var wallcheck_r: RayCast3D = $WallCheckRight
@onready var wallcheck_l: RayCast3D = $WallCheckLeft
@onready var ceilingcheck: ShapeCast3D = $CeilingChecker
@onready var hit_ray: RayCast3D = %HitCheck

@onready var anim_gun: AnimationPlayer = %PistolPlayer
@onready var anim_sword_tree: AnimationTree = %SwordTree
@onready var anim_sword = %SwordPlayer #anim_sword_tree.get("parameters/StateMachine/playback")

@onready var guns: Node3D = %PistolsParent
@onready var sword: Node3D = %Sword

func _ready() -> void:
	
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	debug.text = """Downhill: %s
Slide: %s
Hat: %s
Gravity: %s
Jump: %s
Pos: %s""" % [downhill, round(slide_velocity), round(external_velocity), round(grav_velocity), round(jump_velocity), round(global_position)]
	
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	input_dir = Input.get_vector(input_left, input_right, input_forward, input_back)
	move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	near_wall = (wallcheck.is_colliding())
	
	if Input.is_action_just_pressed(input_jump): jump_buffer = 0.2
	if jump_buffer > 0.0: jump_buffer -= delta
	
	if Input.is_action_just_pressed(input_slide): slide_buffer = 0.5
	if slide_buffer > 0.0: slide_buffer -= delta
	
	if Input.is_action_just_pressed(input_dash): dash_buffer = 0.2
	if dash_buffer > 0.0: dash_buffer -= delta
	
	if shoot_buffer > 0.0: shoot_buffer -= delta
	
	movestuff(delta)
	dash(delta)
	slide(delta)
	jump(delta)
	grav(delta)
	hatstuff(delta)
	combatstuff(delta)
	
	velocity = move_velocity + jump_velocity + dash_velocity + slide_velocity + external_velocity + grav_velocity
	if shoot_buffer > 0.0: deal_shot()
	
	if Input.is_action_pressed(input_switch):
		#switch()
		pass

	move_and_slide()

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
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


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


func movestuff(delta) -> void:
	if move_dir:
		move_velocity = move_velocity.move_toward(move_dir * base_speed, 50.0 * delta)
	else:
		move_velocity = move_velocity.move_toward(Vector3.ZERO, 30.0 * delta)
		if move_velocity.length_squared() < 0.01: move_velocity = Vector3.ZERO

func dash(delta) -> void:
	if dash_charges < 3 and dash_cd.is_stopped(): dash_cd.start()
	if dash_buffer > 0.0 and dash_charges > 0:
		grav_velocity = Vector3.ZERO
		jump_velocity = Vector3.ZERO
		dash_velocity = (dash_velocity + move_dir * 50.0).limit_length(60.0)
		dash_charges -= 1
	dash_velocity = dash_velocity.lerp(Vector3.ZERO, 6.0 * delta)
	if dash_velocity.length_squared() < 1.0: dash_velocity = Vector3.ZERO

func slide(delta) -> void:
	if slide_buffer > 0.0 and is_on_floor():
		slide_buffer = 0.0
		crouch_start()
		var dir = move_dir if move_dir else -transform.basis.z
		slide_velocity = ((velocity.length() + 8 + abs(grav_velocity.y * 0.5)) * dir).slide(get_floor_normal())
	else:
		var lerp_weight = 3.0
		
		var floor_normal = get_floor_normal()
		var floor_angle = get_floor_angle()
		var slide_dir = slide_velocity.normalized()
		downhill = slide_dir.dot(Vector3.DOWN) > 0.0
		if is_on_floor() and floor_angle > 0.05:
			if downhill:
				var slope_accel = floor_angle * 30.0
				slide_velocity += slide_dir * (slope_accel * delta)
		if downhill or not is_on_floor():
			lerp_weight = 1.0
		else:
			lerp_weight = 1.5
		
		slide_velocity = slide_velocity.lerp(Vector3.ZERO, lerp_weight * delta)
		if slide_velocity.length_squared() < 0.5: slide_velocity = Vector3.ZERO
	if slide_velocity.length() <= 2.0:
		crouch_end()
	if crouch_end_requested: crouch_end()

func jump(delta) -> void:
	if jump_buffer > 0.0 and (is_on_floor() or near_wall):
		jump_velocity.y = 12
		jump_buffer = 0.0
		if near_wall and not is_on_floor():
			var wall_normal = wallcheck.get_collision_normal(0)
			jump_velocity.x = wall_normal.x * 12
			jump_velocity.z = wall_normal.z * 12
	elif is_on_floor():
		jump_velocity = Vector3.ZERO
	else:
		jump_velocity = jump_velocity.move_toward(Vector3.ZERO, 25.0 * delta)

func grav(delta) -> void:
	var rising = jump_velocity.y > 1.0
	if not is_on_floor() and not near_wall and not rising and dash_velocity.length() <= 5.0 :
		grav_velocity += get_gravity() * delta
		was_near_wall = false
	elif near_wall:
		if not was_near_wall:
			if grav_velocity.y < -2.0:
				grav_velocity.y = -2.0
				was_near_wall = true
		grav_velocity += get_gravity() / 30 * delta
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


func hatstuff(delta) -> void:
	if Input.is_action_just_pressed("r") and hat.can_use:
		match hat.current_state:
			
			hat.state.EQUIPPED:
				juice.shift(1.7, 70, 0.2)
				await get_tree().create_timer(0.2).timeout
				var facing = -$Head/CameraPivot/Camera3D.global_transform.basis.z
				hat.launch(facing, 30.0)
			
			hat.state.LAUNCHED:
				hat.used = true
				var pull_dir : Vector3 = (hat.global_position - global_position).normalized()
				external_velocity = pull_dir * 25.0
		
			hat.state.LANDED:
				if not hat.used:
					juice.shift(1.7, 60, 0.4)
					await get_tree().create_timer(0.4).timeout
					global_position = hat.global_position + Vector3(0, 0.5, 0)
					hat.reset()
					juice.shift(1.7, 110, 0.1)

	if not Input.is_action_pressed("r"):
		external_velocity = external_velocity.move_toward(Vector3.ZERO, 20.0 * delta)
	elif hat.current_state == hat.state.EQUIPPED:
		external_velocity = external_velocity.move_toward(Vector3.ZERO, 20.0 * delta)

func combatstuff(delta) -> void:
	match current_wpn:
		wpn.GUNS:
			if Input.is_action_pressed(input_attack):
				if !anim_gun.is_playing():
					if shoot_l: anim_gun.play("L_shoot")
					else: anim_gun.play("R_shoot")
					shoot_l = !shoot_l
					shoot_buffer = 0.05
					
		wpn.SWORD:
			if Input.is_action_just_pressed(input_attack):
				match combo_step:
					0:
						combo_step = 1
						anim_sword.play("swing1")
					1:
						combo_step = 2
						anim_sword.play("swing2")
					2:
						combo_step = 3
						anim_sword.play("swing3")
					3:
						pass
		
	if Input.is_action_just_pressed(input_switch):
		match current_wpn:
			wpn.GUNS:
				guns.visible = false
				sword.visible = true
				current_wpn = wpn.SWORD
			wpn.SWORD:
				sword.visible = false
				guns.visible = true
				current_wpn = wpn.GUNS

func deal_shot() -> void:
	shoot_buffer = 0.0
	var cam = %Camera3D
	var space_state = get_world_3d().direct_space_state
	var origin = cam.global_position
	var end = origin + (-cam.global_transform.basis.z * 1000.0)
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	if result:
		
		var hit_data = {
			"damage": 1.0, # replace with function bichazz
			"type": "GUN"
		}
		
		print(result.collider, result.position)
		var body = result.collider
		if body and body.has_method("hit"):
			body.hit(hit_data)

func _on_dash_cd_timeout() -> void:
	if dash_charges < 3: dash_charges += 1

func _on_combo_timer_timeout() -> void:
	combo_step = 0
	anim_sword.play("sheath", 0.15)

func _on_sword_player_animation_finished(anim_name: StringName) -> void:
	print(anim_name)
	match anim_name:
		"swing1", "swing2":
			combo.start()
		"swing3":
			combo.start()
		"sheath":
			combo_step = 0
