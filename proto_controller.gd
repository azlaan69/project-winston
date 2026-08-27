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
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_forward : String = "ui_up"
@export var input_back : String = "ui_down"
@export var input_jump : String = "ui_accept"
@export var input_dash : String = "shift"
@export var input_freefly : String = "freefly"
@export var input_slide : String = "ctrl"

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

var camera_tilt_so_i_dont_go_insane: float = 0.0

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var debug: Label = $CanvasLayer/HUD/Label
@onready var hat: RigidBody3D = get_node("../Hat")

@onready var dash_timer: Timer = $Dash_Timer
@onready var dash_cd: Timer = $Dash_CD
@onready var lock: Timer = $Lock
@onready var jump_coyote: Timer = $WallCoyote

@onready var juice = $Head

@onready var wallcheck: ShapeCast3D = $WallChecker
@onready var wallcheck_r: RayCast3D = $WallCheckRight
@onready var wallcheck_l: RayCast3D = $WallCheckLeft
@onready var ceilingcheck: ShapeCast3D = $CeilingChecker

@onready var anim_p: AnimationPlayer = %PistolPlayer

func _ready() -> void:
	
	check_input_mappings()
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
	
	movestuff(delta)
	dash(delta)
	slide(delta)
	jump(delta)
	grav(delta)
	hatstuff(delta)
	
	if crouch_end_requested: crouch_end()
	
	#if Input.is_action_just_pressed("rmb"):
		#global_position = Vector3.ZERO
		#velocity = Vector3.ZERO
		#dash_charges = 3
		#rotation = Vector3.ZERO
	
	velocity = move_velocity + jump_velocity + dash_velocity + slide_velocity + external_velocity + grav_velocity
	
	#if can_dash and Input.is_action_just_pressed(input_dash) and dash_charges > 0:
		#dash_timer.start()
		#dash_charges -= 1
	#
	#else:
		#move_speed = lerp(move_speed, base_speed, 0.75)
		#
	#if dash_timer.time_left > 0: 
		#move_speed += dash_speed
		#velocity.y = 0

	#
	#if has_gravity and not is_on_floor():
		#if near_wall:
			#velocity.y = -0.5
			#move_speed *= 1.5
		#else:
			#velocity += get_gravity() * delta
#
	#if can_jump:
		#if Input.is_action_just_pressed(input_jump):
			#
			#if near_wall:
				#if wall_running: wall_running = false
				#
				#var wall_normal = get_wall_normal()
				#velocity.y += jump_velocity * 1.5
				#
				#var jump_dir = (wall_normal * 1.0 + (-transform.basis.z)).normalized()
				#move_speed = base_speed
				#velocity.x = jump_dir.x * move_speed
				#velocity.z = jump_dir.z * move_speed
				#lock.start()
				#
			#elif is_on_floor():
				#
				#if dash_timer.time_left > 0.0:
					#velocity.y = jump_velocity
					#velocity *= 2.0
					#lock.start()
					 #
				#else:
					#velocity.y = jump_velocity
#
	#if Input.is_action_pressed(input_slide) and is_on_floor():
		#juice.shift(0.7, 100, 0.0, true)
		#if move_dir:
			#velocity += -transform.basis.z * 10.0 * delta
			#lock.start()
	#if Input.is_action_just_released(input_slide):
		#juice.shift(1.7, 90, 0.0, true)
		
		
	#if not is_on_floor() and lock.time_left <= 0.0:
		#
		#var wall_normal = get_wall_normal()
		#
		#if wall_normal == Vector3.ZERO:
			#wall_normal = -transform.basis.z
		#
		#var parallel = wall_normal.cross(Vector3.UP)
		#if -(transform.basis.z).dot(parallel) < 0:
			#parallel = -parallel
		#
		#if input_dir.y < 0:
			#var stick_force = -wall_normal * 2.0
			#velocity.x = (parallel.x * move_speed) + stick_force.x
			#velocity.z = (parallel.z * move_speed) + stick_force.z
			#wall_running = true
		
	#if can_move and lock.time_left <= 0.0:
		#
		#if move_dir:
			#velocity.x = move_dir.x * move_speed
			#velocity.z = move_dir.z * move_speed
			#
		#elif not decel_locked:
			#velocity.x = lerp(velocity.x, 0.0, 0.2)
			#velocity.z = lerp(velocity.z, 0.0, 0.2)
	 
	if Input.is_action_just_pressed("lmb"):
		juice.shift(1.7, 100, 0.2, false)
		anim_p.play("L_shoot")
	if Input.is_action_just_pressed("rmb"):
		juice.shift(1.7, 100, 0.2, false)
		anim_p.play("R_shoot")
	
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
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
	if Input.is_action_just_pressed(input_dash) and dash_charges > 0:
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
		slide_velocity = ((velocity.length() + 8) * dir).slide(get_floor_normal())
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
			lerp_weight = 4.0 + (floor_angle * 6.0)
		
		slide_velocity = slide_velocity.lerp(Vector3.ZERO, lerp_weight * delta)
		if slide_velocity.length_squared() < 0.5: slide_velocity = Vector3.ZERO
	if slide_velocity == Vector3.ZERO:
		crouch_end()

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

func _on_dash_cd_timeout() -> void:
	if dash_charges < 3: dash_charges += 1

## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_dash and not InputMap.has_action(input_dash):
		push_error("Sprinting disabled. No InputAction found for input_dash: " + input_dash)
		can_dash = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
