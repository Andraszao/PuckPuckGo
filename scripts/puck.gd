extends RigidBody3D

# Configuration options
var power_bar_colors = {
	"white": Color.WHITE,
	"light_blue": Color.LIGHT_BLUE,
	"blue": Color.BLUE,
	"blue_violet": Color(0.541176, 0.168627, 0.886275),
	"purple": Color.PURPLE,
	"purple_red": Color(0.627451, 0.12549, 0.941176),
	"red": Color.RED
}
var power_thresholds = [25, 50, 65, 75, 85, 95]

@export var min_launch_force = 5.0
@export var max_launch_force = 20.0
var launch_direction = Vector3.FORWARD
var is_aiming = false
@export var aim_limit_degrees = 70.0
var aim_indicator = null

# Power bar variables
var power = 0.0  # Current power value
var power_speed = 50.0  # Speed at which the power fluctuates
var power_bar = null  # Power bar indicator
var power_bar_max_height = 1.0  # Maximum height of the power bar

func _ready():
	# Create an aim indicator visual
	var aim_mesh = ImmediateMesh.new()
	aim_indicator = MeshInstance3D.new()
	aim_indicator.mesh = aim_mesh
	add_child(aim_indicator)
	
	# Create a power bar indicator visual
	power_bar = MeshInstance3D.new()
	var power_bar_mesh = BoxMesh.new()
	power_bar_mesh.size = Vector3(0.1, 0.1, 0.1)  # Initial size of the power bar
	power_bar.mesh = power_bar_mesh
	
	# Offset the power bar to the right and raise it above the puck
	power_bar.transform.origin = Vector3(1.0, 0.5, 0.0)  # Adjust the offset as needed
	
	add_child(power_bar)
	power_bar.visible = false  # Hide the power bar initially

func _input(event):
	if event.is_action_pressed("aim_puck"):
		is_aiming = true
		power_bar.visible = true  # Show the power bar when aiming
		power = 0  # Reset the power when starting to aim
	elif event.is_action_released("aim_puck") and is_aiming:
		launch_puck()
		is_aiming = false
		power_bar.visible = false  # Hide the power bar when not aiming

func _physics_process(delta):
	if is_aiming:
		update_aiming()
		update_power_bar(delta)
	else:
		aim_indicator.mesh.clear_surfaces()

func update_aiming():
	var mouse_pos = get_viewport().get_mouse_position()
	var puck_pos = get_viewport().get_camera_3d().unproject_position(global_transform.origin)
	var direction = (mouse_pos - puck_pos).normalized()
	
	# Limit the aiming direction to a range relative to the puck's forward direction
	var aim_limit_radians = deg_to_rad(aim_limit_degrees)
	var angle = atan2(direction.y, direction.x)
	angle = clamp(angle, -aim_limit_radians, aim_limit_radians)
	
	# Calculate the launch direction relative to the puck's forward direction
	var puck_forward = -global_transform.basis.z
	var puck_right = global_transform.basis.x
	launch_direction = puck_forward * cos(angle) + puck_right * sin(angle)
	
	# Update the aim indicator
	update_aim_indicator()

func launch_puck():
	var power_ratio = power / 100.0
	var launch_force = min_launch_force + (max_launch_force - min_launch_force) * pow(power_ratio, 2)
	apply_central_impulse(launch_direction * launch_force)
	
	# Add rotation to the puck based on the launch direction
	var rotation_strength = 5.0  # Adjust the rotation strength as needed
	apply_torque_impulse(Vector3.UP * rotation_strength)
	
	power = 0  # Reset the power after launching

func update_aim_indicator():
	var aim_mesh = aim_indicator.mesh
	aim_mesh.clear_surfaces()
	aim_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	aim_mesh.surface_add_vertex(Vector3.ZERO)
	aim_mesh.surface_add_vertex(launch_direction * 2)  # Adjust the length of the indicator as needed
	aim_mesh.surface_end()

func update_power_bar(delta):
	power += power_speed * delta
	if power > 100 or power < 0:
		power_speed *= -1  # Reverse the direction of power change
	power = clamp(power, 0, 100)  # Clamp the power between 0 and 100
	
	update_power_bar_size()
	update_power_bar_position()
	update_power_bar_color()

func update_power_bar_size():
	var power_ratio = power / 100.0
	power_bar.mesh.size.y = power_bar_max_height * power_ratio

func update_power_bar_position():
	var power_ratio = power / 100.0
	# Calculate the position of the power bar based on its height
	# The power bar grows upwards from the center of the puck
	power_bar.transform.origin.y = 0.5 + (power_bar_max_height * power_ratio) / 2

func update_power_bar_color():
	var power_bar_material = StandardMaterial3D.new()
	var color_key = ""
	
	if power <= power_thresholds[0]:
		color_key = "white"
	elif power <= power_thresholds[1]:
		color_key = "light_blue"
	elif power <= power_thresholds[2]:
		color_key = "blue"
	elif power <= power_thresholds[3]:
		color_key = "blue_violet"
	elif power <= power_thresholds[4]:
		color_key = "purple"
	elif power <= power_thresholds[5]:
		color_key = "purple_red"
	else:
		color_key = "red"
	
	power_bar_material.albedo_color = power_bar_colors[color_key]
	
	# Ensure the mesh has a surface before setting the override material
	if power_bar.mesh.get_surface_count() > 0:
		power_bar.set_surface_override_material(0, power_bar_material)

