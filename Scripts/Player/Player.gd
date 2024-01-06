class_name Player
extends CharacterBody2D

# following godot style guide
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
# following tutorial 
# https://www.youtube.com/watch?v=mAbG8Oi-SvQ&list=PL9FzW-m48fn2SlrW0KoLT4n5egNdX-W9a

# Signals
# Enums
# Constants
const SPEED : float = 60
const ACCELERATION : float = 80
const FRICTION : float = 2000

# Export Variables
# Public Variables
# Private Variables
var direction : Vector2 = Vector2.ZERO
# Onready variables
@onready var animation_player = $Animations/AnimationPlayer





func _physics_process(delta):
	move_player(delta)
	update_animation()


#region General Methods
func move_player(delta) -> void:
	direction = Input.get_vector("Left", "Right", "Up", "Down") # already normalized
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


func update_animation() -> void:
	if velocity != Vector2.ZERO:
		if direction.x > 0:
			animation_player.play("RunRight")
		elif direction.x < 0:
			animation_player.play("RunLeft")
		elif direction.y < 0:
			animation_player.play("RunUp")
		elif direction.y > 0:
			animation_player.play("RunDown")
	else:
		animation_player.play("IdleRight")

#endregion
