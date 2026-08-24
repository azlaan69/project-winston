# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_dash : bool = false
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_velocity : float = 6.0
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
var wall_running : bool = false
var near_wall : bool = false
var decel_locked : bool = false

var input_dir = 0.0
var move_dir = 0.0

var dash_charges = 3

var camera_tilt_so_i_dont_go_insane: float = 0.0

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var debug: Label = $CanvasLayer/HUD/Label
@onready var hat: RigidBody3D = get_node("../Hat")

@onready var dash_timer: Timer = $Dash_Timer
@onready var dash_cd: Timer = $Dash_CD
@onready var lock: Timer = $Lock
@onready var jump_coyote: Timer = $WallCoyote

@onready var playback = $Head/SwordTree.get("parameters/Movements/playback")
@onready var juice = $Head

@onready var wallcheck: ShapeCast3D = $WallChecker

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
	debug.text = str(juice.shift_allowed)
	
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	input_dir = Input.get_vector(input_left, input_right, input_forward, input_back)
	move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	near_wall = (is_on_wall() and not is_on_floor())
	
	if can_dash and Input.is_action_just_pressed(input_dash) and dash_charges > 0:
		dash_timer.start()
		dash_charges -= 1
	
	else:
		move_speed = lerp(move_speed, base_speed, 0.75)
		
	if dash_timer.time_left > 0: 
		move_speed += dash_speed
		velocity.y = 0
	if dash_charges < 3 and dash_cd.is_stopped(): dash_cd.start()
	
	if has_gravity and not is_on_floor():
		if near_wall:
			velocity.y = -0.5
			move_speed *= 1.5
		else:
			velocity += get_gravity() * delta

	if can_jump:
		if Input.is_action_just_pressed(input_jump):
			
			if near_wall:
				if wall_running: wall_running = false
				
				var wall_normal = get_wall_normal()
				velocity.y += jump_velocity * 1.5
				
				var jump_dir = (wall_normal * 1.0 + (-transform.basis.z)).normalized()
				move_speed = base_speed
				velocity.x = jump_dir.x * move_speed
				velocity.z = jump_dir.z * move_speed
				lock.start()
				
			elif is_on_floor():
				
				if dash_timer.time_left > 0.0:
					velocity.y = jump_velocity
					velocity *= 2.0
					lock.start()
					 
				else:
					velocity.y = jump_velocity

	if Input.is_action_pressed(input_slide) and is_on_floor():
		juice.shift(0.7, 100, 0.0, true)
		if move_dir:
			velocity += -transform.basis.z * 10.0 * delta
			lock.start()
	if Input.is_action_just_released(input_slide):
		juice.shift(1.7, 90, 0.0, true)
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
		
	if can_move and lock.time_left <= 0.0:
		
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			
		elif not decel_locked:
			velocity.x = lerp(velocity.x, 0.0, 0.2)
			velocity.z = lerp(velocity.z, 0.0, 0.2)
	
	if Input.is_action_just_pressed("r") and hat.can_use:
		hatstuff(delta)
	
	if Input.is_action_just_pressed("lmb"):
		playback.travel("attack")
	
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
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


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


func hatstuff(delta) -> void:
	match hat.current_state:
		
		hat.state.EQUIPPED:
			juice.shift(1.7, 70, 0.2)
			await get_tree().create_timer(0.2).timeout
			var facing = -$Head/CameraPivot/Camera3D.global_transform.basis.z
			hat.launch(facing, 30.0)
		
		hat.state.LAUNCHED:
			hat.used = true
			lock.start()
			decel_locked = true
			var pull_dir : Vector3 = (hat.global_position - global_position).normalized()
			velocity = pull_dir * 25.0
	
		hat.state.LANDED:
			if not hat.used:
				juice.shift(1.7, 60, 0.4)
				await get_tree().create_timer(0.4).timeout
				global_position = hat.global_position + Vector3(0, 0.5, 0)
				hat.reset()
				juice.shift(1.7, 110, 0.1)

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
