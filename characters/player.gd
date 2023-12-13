extends CharacterBody2D

enum States {FLOOR, AIR, CLIMBING}
@export var speed : float = 300.0
const JUMP_VELOCITY = -600.0
var can_climb : bool = false
var is_duck : bool = false
var state: States = States.AIR

@onready var animation_tree : AnimationTree = $AnimationTree

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	animation_tree.active = true
	
func _process(_delta):
	update_animation_parameters()

func _draw():
#	draw_line($RayClimb.position, ($RayClimb.position+$RayClimb.target_position)*1,Color(255,0,0),4)
	pass

func _physics_process(delta):
	var dir_hori = Input.get_axis("left", "right")
	var dir_vert = Input.get_axis("up", "down")
	match state:
		States.FLOOR:
			floor_physics_process(delta, dir_hori, dir_vert)
		States.AIR:
			air_physics_process(delta, dir_hori, dir_vert)
		States.CLIMBING:
			climbing_physics_process(delta, dir_hori, dir_vert)
		
	move_and_slide()

func floor_physics_process(_delta, dir_hori, dir_vert):
	if not is_on_floor():
		state = States.AIR
		return
	elif dir_vert != 0:
		if $RayClimb.is_colliding():
			var tile_map:TileMap = $RayClimb.get_collider()
			var point = tile_map.local_to_map($RayClimb.get_collision_point())
			var cell = tile_map.get_cell_tile_data(3, point)
			if cell:
				var data = cell.get_custom_data("name")
				if (dir_vert == 1 and data == "ROPE_TOP") or (dir_vert == -1 and data == "ROPE"):
					state = States.CLIMBING
					velocity.x = 0.0
					position.x = tile_map.map_to_local(point).x
					position.y += 16.0 * dir_vert;
					return
	#	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		if dir_vert == 1:
			pass
		else:
			velocity.y = JUMP_VELOCITY
			state = States.AIR
		
	if dir_hori:
		velocity.x = dir_hori * speed
		$Sprite2D.scale.x = dir_hori
	else:
		velocity.x =  move_toward(velocity.x, 0, speed)
		
#	is_duck = direction_vert == 1 and direction_hori == 0
	
func air_physics_process(delta, dir_hori, dir_vert):
	# Add the gravity.
	if is_on_floor():
		state = States.FLOOR
		return
#	elif can_climb and $RayClimb.is_colliding() and direction_vert == -1:
#		state = States.CLIMBING
#		velocity.x = 0.0
#		if $RayClimb.is_colliding():
#			var tile_map:TileMap = $RayClimb.get_collider()
#			position.x = tile_map.map_to_local(tile_map.local_to_map($RayClimb.get_collision_point())).x
#		return
	
	velocity.y += gravity * delta
	
	if dir_hori:
		velocity.x = dir_hori * speed
		$Sprite2D.scale.x = dir_hori
	else:
		velocity.x =  move_toward(velocity.x, 0, speed)
	
func climbing_physics_process(_delta, dir_hori, dir_vert):
	if dir_vert != 0:
		if (not $RayClimb.is_colliding()) or is_on_floor():
			state = States.FLOOR
			return
#	elif Input.is_action_just_pressed("jump") and direction_hori:
#		velocity.y = JUMP_VELOCITY/2
#		velocity.x = direction_hori * speed
#		state = States.AIR
#		return

	velocity.y = dir_vert * speed/2
	
	
	
func update_animation_parameters():
#	match state:
#		States.AIR: # Está no Ar
##			animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
#			animation_tree["parameters/conditions/is_idle"] = false
#			animation_tree["parameters/conditions/is_walking"] = false
#			animation_tree["parameters/conditions/is_jump"] = true
#			animation_tree["parameters/conditions/is_climb"] = false
#			animation_tree["parameters/conditions/is_duck"] = false
#		States.FLOOR: # Está no chão
##			animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
#			animation_tree["parameters/conditions/is_jump"] = false
#			animation_tree["parameters/conditions/is_climb"] = false
#			if velocity.x != 0.0: # Em movimento no chão
#				animation_tree["parameters/conditions/is_idle"] = false
#				animation_tree["parameters/conditions/is_walking"] = true
#				animation_tree["parameters/conditions/is_duck"] = false
#			else: # Parado no chão
#				animation_tree["parameters/conditions/is_walking"] = false
#				if is_duck and not can_climb:
#					animation_tree["parameters/conditions/is_duck"] = true
#					animation_tree["parameters/conditions/is_idle"] = false
#				else:
#					animation_tree["parameters/conditions/is_idle"] = true
#					animation_tree["parameters/conditions/is_duck"] = false
#		States.CLIMBING: # Está numa corta ou escada
#			animation_tree["parameters/conditions/is_climb"] = true
##			if velocity.normalized().y != 0.0:
##				animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
##			else:
##				animation_tree.process_mode = Node.PROCESS_MODE_DISABLED
#			animation_tree["parameters/conditions/is_idle"] = false
#			animation_tree["parameters/conditions/is_walking"] = false
#			animation_tree["parameters/conditions/is_jump"] = false
#			animation_tree["parameters/conditions/is_duck"] = false
	pass
