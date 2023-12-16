extends CharacterBody2D

@export var speed : float = 50.0
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var ray_margin : RayCast2D = $RayMargin
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	animation_tree.active = true
	velocity.x = -speed
	pass


func _process(delta):
	pass

func _physics_process(delta):
	velocity.y += gravity * delta
	
	if not ray_margin.is_colliding():
		velocity.x *= -1
		$Sprite2D.scale.x *= -1
	move_and_slide()
