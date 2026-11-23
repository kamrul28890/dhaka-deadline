extends Node3D
class_name TrafficPoliceOfficer

var signaling_state: String = "idle"
var arm_left: Node3D
var arm_right: Node3D
var baton: Node3D
var whistle_active: bool = false
var gesture_timer: float = 0.0

func _ready() -> void:
	arm_left = get_node_or_null("ArmLeft")
	arm_right = get_node_or_null("ArmRight")

func set_signaling_state(state: String) -> void:
	signaling_state = state
	if not is_inside_tree():
		return
	if arm_left == null:
		arm_left = get_node_or_null("ArmLeft")
	if arm_right == null:
		arm_right = get_node_or_null("ArmRight")

	if signaling_state == "stop":
		if is_instance_valid(arm_right):
			arm_right.rotation = Vector3(-PI * 0.48, 0.0, 0.15)
		if is_instance_valid(arm_left):
			arm_left.rotation = Vector3(-PI * 0.48, 0.0, -0.15)
	elif signaling_state == "wave":
		if is_instance_valid(arm_right):
			arm_right.rotation = Vector3(-PI * 0.25, 0.5, 0.0)
		if is_instance_valid(arm_left):
			arm_left.rotation = Vector3(0.0, 0.0, -0.1)
	else:
		signaling_state = "idle"
		if is_instance_valid(arm_right):
			arm_right.rotation = Vector3.ZERO
		if is_instance_valid(arm_left):
			arm_left.rotation = Vector3.ZERO

func _process(delta: float) -> void:
	if signaling_state == "wave":
		gesture_timer += delta * 4.0
		if is_instance_valid(arm_right):
			arm_right.rotation.y = 0.4 + sin(gesture_timer) * 0.35
			arm_right.rotation.x = -PI * 0.25 + cos(gesture_timer) * 0.1
