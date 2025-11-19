extends Node2D

onready var animation_player := $AnimatedSprite

var start_scale := 0.5
var hurt = false
var velocity := Vector2.ZERO

func _ready() -> void:
	if Engine.editor_hint or not owner:
		set_physics_process(false)
		return

	yield(owner, "ready")
	if not owner.get("velocity") is Vector2:
		set_physics_process(false)
		printerr("Skin expected a owner node with a velocity property but the owner node doesn't have those. Turning off skin.")


func play(animation: String) -> void:
	animation_player.play(animation)


func _physics_process(_delta: float) -> void:
	if not is_zero_approx(velocity.x):
		scale.x = sign(velocity.x) * 0.25

	var is_jumping = velocity.y < 0 and not owner.is_on_floor()
	if not hurt:
		if is_jumping:
			play("jump")
		elif owner.is_on_floor():
			if not is_zero_approx(velocity.x):
				play("run")
			else:
				play("idle")

func _on_Character_hurt():
	hurt = true
	play("hurt")


func _on_AnimatedSprite_animation_finished():
	hurt = false
