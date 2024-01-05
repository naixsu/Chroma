class_name Player
extends CharacterBody2D

# following godot style guide
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html

const SPEED : float = 300.0

func _physics_process(delta):
	move_player()


#region General Methods
func move_player() -> void:
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = direction * SPEED
	move_and_slide()
#endregion
