class_name Player
extends CharacterBody2D

# following godot style guide
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
# following tutorial 
# https://www.youtube.com/watch?v=mAbG8Oi-SvQ&list=PL9FzW-m48fn2SlrW0KoLT4n5egNdX-W9a

const SPEED : float = 60
const ACCELERATION : float = 80
const FRICTION : float = 2000

func _physics_process(delta):
	move_player(delta)


#region General Methods
func move_player(delta) -> void:
	var direction = Input.get_vector("Left", "Right", "Up", "Down") # already normalized
	# velocity = direction * SPEED * ACCELERATION * delta
	
	# might not need the if-else below
	if direction != Vector2.ZERO:
		velocity = direction * SPEED * ACCELERATION * delta
		#velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	move_and_slide()
	
	#var input_vector = Vector2.ZERO
	#input_vector.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	#input_vector.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	#input_vector = input_vector.normalized()
	#
	#if input_vector != Vector2.ZERO:
		#velocity += input_vector * ACCELERATION * delta
		#velocity = velocity.limit_length(SPEED * delta)
	#else:
		#velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

#endregion
