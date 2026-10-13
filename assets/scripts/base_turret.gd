class_name BaseTurret
extends Node3D


@export_group("Firing")
@export var bullet_velocity := 50.0
@export var bullet_scene: PackedScene
@export var bullet_marker: Marker3D



@export_group("Tracking")

@export_subgroup("Turret")
@export var max_angle := 360.0
@export var min_angle := -360.0
@export var turn_speed := 10.0

@export_range(0.0, 1.0, 0.05) var lead := 0.5


@export_subgroup("Gun")
@export var gun : Node3D
@export var max_angle_gun := 360.0
@export var min_angle_gun := 0.0
@export var turn_speed_gun := 10.0

@export_range(0.0, 1.0, 0.05) var gun_lead := 0.5

var limit_angle_min: float
var limit_angle_max: float

var gun_limit_min: float
var gun_limit_max: float


var player = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	limit_angle_min = deg_to_rad(min_angle)
	limit_angle_max = deg_to_rad(max_angle)

	gun_limit_min = deg_to_rad(min_angle_gun)
	gun_limit_max = deg_to_rad(max_angle_gun)

func fetch_predicted() -> Vector3:
	var time : float = global_position.distance_to(player.global_position) / bullet_velocity
	var predicted_pos : Vector3 = player.global_position + (player.velocity * time * lead)
	
	predicted_pos.y = global_position.y
	
	if predicted_pos.is_equal_approx(global_position): 
		return Vector3.ZERO
	
	return predicted_pos

func fetch_predicted_gun() -> Vector3:
	var gun_time : float = global_position.distance_to(player.global_position + Vector3(0.0, 2.0, 0.0)) / bullet_velocity
	var predicted_pos_gun : Vector3 = player.global_position + (player.velocity * gun_time * gun_lead)
	
	return predicted_pos_gun
	

func track_predicted(delta) -> void:
	var predicted_pos = fetch_predicted()
	var dir = global_position.direction_to(predicted_pos)
	var target_yaw = atan2(-dir.x, -dir.z)
	
	target_yaw = clampf(target_yaw, limit_angle_min, limit_angle_max)
	
	global_rotation.y = lerp_angle(global_rotation.y, target_yaw, turn_speed * delta)

func track_predicted_gun(delta) -> void:
	var predicted_pos_gun = fetch_predicted_gun()
	var height_difference : float = predicted_pos_gun.y - gun.global_position.y
	var flat_dist : float = Vector2(predicted_pos_gun.x, predicted_pos_gun.z).distance_to(Vector2(global_position.x, global_position.z))
	
	var target_pitch = atan2(height_difference, flat_dist)
	
	target_pitch = clampf(target_pitch, gun_limit_min, gun_limit_max)
	
	gun.global_rotation.x = lerp_angle(gun.global_rotation.x, target_pitch, turn_speed_gun * delta)

func fire() -> void:
	if !bullet_marker or !bullet_scene: return
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = bullet_marker.global_position
	bullet.global_transform = gun.global_transform
	bullet.speed = bullet_velocity
