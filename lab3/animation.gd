extends Node2D

@onready var anim_player = $AnimationPlayer
@onready var btn_idle = $UI/Button
@onready var btn_run = $UI/Button2
@onready var btn_jump = $UI/Button3
@onready var btn_punch = $UI/Button4

func _ready():
	btn_idle.pressed.connect(func(): play_anim("Idle"))
	btn_run.pressed.connect(func(): play_anim("Run"))
	btn_jump.pressed.connect(func(): play_anim("Jump"))
	btn_punch.pressed.connect(_on_punch_pressed)

func _on_punch_pressed():
	anim_player.play("Punch")
	await anim_player.animation_finished
	anim_player.play("Idle")

func play_anim(anim_name: String):
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
