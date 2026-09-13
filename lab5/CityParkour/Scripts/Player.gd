extends CharacterBody3D
## City Parkour player controller.
## Based on the 3D Platformer Starter Kit controller by SD Studios,
## re-fitted for the Poly Pizza "Animated Woman" model.

@export_category("Player Properties")
@export var move_speed := 7.0
@export var jump_force := 8.0
@export var follow_lerp_factor := 6.0
@export var gravity_scale := 2.0

@export_group("Game Juice")
@export var jump_stretch_size := Vector3(0.8, 1.2, 0.8)

# Animation names that come from the imported FBX
const ANIM_IDLE := "Armature|Idle"
const ANIM_WALK := "Armature|Walking"
const ANIM_RUN := "Armature|Running"
const ANIM_JUMP := "Armature|Jump2"
const ANIM_FLIP := "Armature|Jump"
const ANIM_HURT := "Armature|Death"

var is_grounded := false
var can_double_jump := false
var is_hurt := false
var invulnerable := false

# timers, counted down in _physics_process (no awaits, so a scene change
# in the middle of a hit can never leave a dangling coroutine)
var _hurt_timer := 0.0
var _invuln_timer := 0.0

@onready var model: Node3D = $Model
@onready var animation: AnimationPlayer = $Model/AnimationPlayer
@onready var spring_arm: Node3D = %Gimbal
@onready var particle_trail: CPUParticles3D = $ParticleTrail
@onready var footsteps: AudioStreamPlayer3D = $Footsteps

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	add_to_group("Player")
	# The FBX ships every clip as a one-shot; the looping ones must be told to loop.
	for clip_name in [ANIM_IDLE, ANIM_WALK, ANIM_RUN]:
		if animation.has_animation(clip_name):
			animation.get_animation(clip_name).loop_mode = Animation.LOOP_LINEAR


func _physics_process(delta: float) -> void:
	_tick_hit_timers(delta)
	_handle_animations()
	_handle_input(delta)

	is_grounded = is_on_floor()
	if is_grounded:
		can_double_jump = true

	if not is_hurt and Input.is_action_just_pressed("jump"):
		if is_grounded:
			_perform_jump()
		elif can_double_jump:
			_perform_flip_jump()

	velocity.y -= gravity * gravity_scale * delta
	move_and_slide()


func _process(delta: float) -> void:
	# Smoothly follow the player's position with the camera gimbal
	spring_arm.position = spring_arm.position.lerp(position, delta * follow_lerp_factor)

	if is_moving():
		var look_direction := Vector2(velocity.z, velocity.x)
		model.rotation.y = lerp_angle(model.rotation.y, look_direction.angle(), delta * 12.0)


func _handle_input(_delta: float) -> void:
	if is_hurt:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * _delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * _delta)
		return

	var move_direction := Vector3.ZERO
	move_direction.x = Input.get_axis("move_left", "move_right")
	move_direction.z = Input.get_axis("move_forward", "move_back")
	move_direction = move_direction.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed


func is_moving() -> bool:
	return Vector2(velocity.x, velocity.z).length() > 0.2


func _perform_jump() -> void:
	AudioManager.jump_sfx.pitch_scale = 1.12
	AudioManager.jump_sfx.play()
	_jump_tween()
	_play(ANIM_JUMP, 0.1)
	velocity.y = jump_force


func _perform_flip_jump() -> void:
	can_double_jump = false
	AudioManager.jump_sfx.pitch_scale = 0.8
	AudioManager.jump_sfx.play()
	_play(ANIM_FLIP, 0.1, 2.0)
	velocity.y = jump_force * 0.95


func _jump_tween() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", jump_stretch_size, 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.1)


func _play(clip_name: String, blend := 0.2, speed := 1.0) -> void:
	if animation.has_animation(clip_name):
		animation.play(clip_name, blend, speed)


func _handle_animations() -> void:
	particle_trail.emitting = false
	footsteps.stream_paused = true

	if is_hurt:
		return

	if is_on_floor():
		if is_moving():
			_play(ANIM_RUN, 0.2, 1.4)
			particle_trail.emitting = true
			footsteps.stream_paused = false
		else:
			_play(ANIM_IDLE, 0.3)


func _tick_hit_timers(delta: float) -> void:
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		if _invuln_timer <= 0.0:
			invulnerable = false
	if is_hurt:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0:
			is_hurt = false
			respawn()


## Called by hazards. Knocks the player back, costs a life and respawns.
func hit(from_position := Vector3.ZERO) -> void:
	if is_hurt or invulnerable:
		return
	is_hurt = true
	invulnerable = true
	_hurt_timer = 0.6
	_invuln_timer = 1.6
	_play(ANIM_HURT, 0.1, 1.6)

	var push := global_position - from_position
	push.y = 0.0
	if push.length() < 0.01:
		push = -model.global_transform.basis.z
	velocity = push.normalized() * 6.0
	velocity.y = 5.0

	GameManager.lose_life()


func respawn() -> void:
	if not is_inside_tree():
		return
	is_hurt = false
	velocity = Vector3.ZERO
	global_position = GameManager.spawn_position
	spring_arm.position = GameManager.spawn_position
	_play(ANIM_IDLE, 0.1)
