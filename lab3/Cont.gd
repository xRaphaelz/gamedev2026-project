extends CharacterBody2D

@onready var anim_sprite = $Animation  # หรือ AnimationPlayer

var is_punching = false

func _physics_process(delta):
	if Input.is_key_pressed(KEY_F) and not is_punching:
		punch()

func punch():
	is_punching = true
	anim_sprite.play("Punch")
	await anim_sprite.animation_finished
	is_punching = false
	anim_sprite.play("Idle")
