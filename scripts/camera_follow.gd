extends Camera3D

var puck  # Reference to the puck scene
var offset = Vector3(0, 2, 4)  # Adjust the offset as needed
var look_at_offset = Vector3(0, 0, 0)  # Adjust the look-at offset as needed
var follow_speed = 5.0  # Adjust the follow speed as needed

func _ready():
	puck = get_parent().get_node("/root/shuffleboard/puck")

func _process(delta):
	if puck:
		# Update the camera's position relative to the puck
		var target_position = puck.global_transform.origin + offset
		global_transform.origin = lerp(global_transform.origin, target_position, delta * follow_speed)

		# Make the camera look at the puck with an offset
		var look_at_position = puck.global_transform.origin + look_at_offset
		look_at(look_at_position, Vector3.UP)
