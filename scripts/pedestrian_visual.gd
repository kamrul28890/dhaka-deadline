extends Node3D

const MODELS = [preload("res://assets/models/pedestrian_casual.glb"), preload("res://assets/models/pedestrian_older.glb")]
var manager: Node
var variant: int = 0
var animation: AnimationPlayer

func _ready() -> void:
	var model: Node3D = MODELS[variant%MODELS.size()].instantiate()
	model.scale = Vector3.ONE*0.95
	model.position.y = 0.08
	add_child(model)
	animation = model.find_children("*", "AnimationPlayer", true, false)[0]
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	for clip in ["idle", "walk"]:
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.play("idle")

func _physics_process(_delta: float) -> void:
	if manager.paused_sim:
		animation.pause()
		return
	var velocity: Vector3 = get_parent().velocity
	var speed: float = Vector2(velocity.x, velocity.z).length()
	var clip: String = "walk" if speed > 0.1 else "idle"
	if animation.current_animation != clip or not animation.is_playing():
		animation.play(clip)
	animation.speed_scale = speed/1.25 if clip == "walk" else 1.0
	if speed > 0.1:
		rotation.y = atan2(velocity.x, velocity.z)
