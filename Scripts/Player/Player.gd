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
var _direction : Vector2 = Vector2.ZERO

# Onready variables
@onready var animation_player = $Animations/AnimationPlayer
@onready var animation_tree = $Animations/AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")


func _physics_process(delta):
	move_player(delta)
	update_animation()


#region General Methods
func move_player(delta) -> void:
	_direction = Input.get_vector("Left", "Right", "Up", "Down") # already normalized
	# velocity = _direction * SPEED * ACCELERATION * delta
	
	# might not need the if-else below
	if _direction != Vector2.ZERO:
		velocity = _direction * SPEED * ACCELERATION * delta
		#velocity = velocity.move_toward(_direction * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	move_and_slide()


func update_animation() -> void:
	if _direction != Vector2.ZERO:
		animation_tree.set("parameters/Idle/blend_position", _direction)
		animation_tree.set("parameters/Run/blend_position", _direction)
		animation_state.travel("Run")
	else:
		animation_state.travel("Idle")

#endregion
