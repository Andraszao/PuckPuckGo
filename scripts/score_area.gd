extends Area3D

var points = 3
var puck_inside = false
var points_awarded = false

# Reference to the player's score label in the UI
@onready var score_label = get_parent().get_node("score_control/score_label")

func _on_score_area_collision_body_entered(body):
	if body.is_in_group("puck"):
		puck_inside = true
		points_awarded = false
		print("Puck entered the scoring zone")

func _on_score_area_collision_body_exited(body):
	if body.is_in_group("puck"):
		puck_inside = false
		print("Puck exited the scoring zone")

func _physics_process(delta):
	if puck_inside and not points_awarded:
		var puck_velocity = get_tree().get_nodes_in_group("puck")[0].linear_velocity
		print("Puck velocity: ", puck_velocity)
		if puck_velocity.length() < 0.5:  # Increased threshold to 0.5
			award_points()
			points_awarded = true

func award_points():
	# Get the current score from the score label
	var current_score = int(score_label.text)
	
	# Update the score by adding the points
	current_score += points
	
	# Update the score label in the UI
	score_label.text = str(current_score)
	
	print("Puck stopped in the scoring zone. Awarded ", points, " points!")
