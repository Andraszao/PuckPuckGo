extends RigidBody3D

var min_launch_force = 5.0
var max_launch_force = 20.0
var launch_direction = Vector3.FORWARD
var is_aiming = false
var aim_limit_degrees = 70.0
var aim_indicator = null

# Power bar variables
var power = 0.0  # Current power value
var power_speed = 50.0  # Speed at which the power fluctuates
var power_bar = null  # Power bar indicator
var power_bar_max_height = 1.0  # Maximum height of the power bar

func _ready():
	# Create the aim indicator (e.g., an arrow or a line)
	var aim_mesh = ImmediateMesh.new()
	aim_indicator = MeshInstance3D.new()
	aim_indicator.mesh = aim_mesh
	add_child(aim_indicator)
	
	# Create the power bar indicator
	power_bar = MeshInstance3D.new()
	var power_bar_mesh = BoxMesh.new()
	power_bar_mesh.size = Vector3(0.1, 0.5, 0.1)  # Adjust the size of the power bar
	power_bar.mesh = power_bar_mesh
	
	# Offset the power bar to the right and raise it on the Y-axis
	power_bar.transform.origin = Vector3(1.0, 0.5, 0.0)  # Adjust the offset as needed
	
	add_child(power_bar)

func _input(event):
	if event.is_action_pressed("aim_puck"):
		is_aiming = true
		power_bar.visible = true  # Show the power bar when aiming
	elif event.is_action_released("aim_puck") and is_aiming:
		launch_puck()
		is_aiming = false
		power_bar.visible = false  # Hide the power bar when not aiming

func _physics_process(delta):
	if is_aiming:
		var mouse_pos = Vector3(get_viewport().get_mouse_position().x, get_viewport().get_mouse_position().y, 0)
		var viewport_size = Vector3(get_viewport().size.x, get_viewport().size.y, 0)
		var direction = (mouse_pos - viewport_size / 2).normalized()
		
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
		
		# Update the power bar
		update_power_bar(delta)
	else:
		# Hide the aim indicator when not aiming
		aim_indicator.mesh.clear_surfaces()

func launch_puck():
	var launch_force = min_launch_force + (max_launch_force - min_launch_force) * (power / 100.0)
	apply_central_impulse(launch_direction * launch_force)
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
	
	# Update the power bar's height based on the power value
	var power_ratio = power / 100.0
	power_bar.mesh.size.y = power_bar_max_height * power_ratio
	
	# Update the power bar's color based on the power level
	var power_bar_material = StandardMaterial3D.new()
	if power <= 25:
		power_bar_material.albedo_color = Color.WHITE
	elif power <= 50:
		power_bar_material.albedo_color = Color.LIGHT_BLUE
	elif power <= 65:
		power_bar_material.albedo_color = Color.BLUE
	elif power <= 75:
		power_bar_material.albedo_color = Color(0.541176, 0.168627, 0.886275)  # BLUE_VIOLET
	elif power <= 85:
		power_bar_material.albedo_color = Color.PURPLE
	elif power <= 95:
		power_bar_material.albedo_color = Color(0.627451, 0.12549, 0.941176)  # PURPLE_RED
	else:
		power_bar_material.albedo_color = Color.RED
	
	# Ensure the mesh has a surface before setting the override material
	if power_bar.mesh.get_surface_count() > 0:
		power_bar.set_surface_override_material(0, power_bar_material)
