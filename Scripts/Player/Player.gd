extends CharacterBody2D
class_name Player

const SPEED = 300.0

func _physics_process(delta):
	
	move_player()


#region General Methods
func move_player() -> void:
	var direction = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = direction * SPEED
	move_and_slide()
#endregion
