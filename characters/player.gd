extends CharacterBody2D

enum States {FLOOR, AIR, CLIMBING}
@export var speed : float = 300.0
const JUMP_VELOCITY = -600.0
var state: States = States.AIR
var is_duck: bool = false
var original_target_position
var state_machine

@onready var animation_tree : AnimationTree = $AnimationTree

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	animation_tree.active = true
	state_machine = $AnimationTree.get('parameters/playback')
	original_target_position = $RayClimb.target_position
	$RayDown.position.y += 70 # Tamanho do Tile
	
func _process(_delta):
	update_animation_parameters()

func _draw():
#	draw_line($RayClimb.position, ($RayClimb.position+$RayClimb.target_position)*1,Color(255,0,0),4)
#	draw_line($RayDown.position, ($RayDown.position+$RayDown.target_position)*1,Color(255,0,0),4)
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
		$RayClimb.target_position.y = original_target_position.y + 1
		if $RayClimb.is_colliding():
			var tile_map:TileMap = $RayClimb.get_collider()
			var point = tile_map.local_to_map($RayClimb.get_collision_point())
			var cell = tile_map.get_cell_tile_data(3, point)
			if cell:
				var data = cell.get_custom_data("name")
				if (dir_vert == 1 and data == "ROPE_TOP") or (dir_vert == -1 and data == "ROPE"):
					if is_duck: is_duck = false
					state = States.CLIMBING
					velocity.x = 0.0
					position.x = tile_map.map_to_local(point).x
					position.y += 16.0 * dir_vert;
					return
	
	is_duck = dir_vert == 1
		
	#	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		if dir_vert == 1:
			if $RayDown.is_colliding() and dir_hori == 0:
				position.y += 10.0 * dir_vert;
				if is_duck: is_duck = false
				state = States.AIR
				return
		else:
			if is_duck: is_duck = false
			velocity.y = JUMP_VELOCITY
			state = States.AIR
			return
		
	if dir_hori:
		if is_duck: is_duck = false
		velocity.x = dir_hori * speed
		$Sprite2D.scale.x = dir_hori
	else:
		velocity.x =  move_toward(velocity.x, 0, speed)
	
func air_physics_process(delta, dir_hori, dir_vert):
	# Add the gravity.
	if is_on_floor():
		state = States.FLOOR
		return
	elif $RayClimb.is_colliding() and dir_vert == -1:
		state = States.CLIMBING
		velocity.x = 0.0
		var tile_map:TileMap = $RayClimb.get_collider()
		position.x = tile_map.map_to_local(tile_map.local_to_map($RayClimb.get_collision_point())).x
		return
	
	velocity.y += gravity * delta
	
	if dir_hori:
		velocity.x = dir_hori * speed
		$Sprite2D.scale.x = dir_hori
	else:
		velocity.x =  move_toward(velocity.x, 0, speed)
	
func climbing_physics_process(_delta, dir_hori, dir_vert):
	if dir_vert != 0:
		$RayClimb.target_position.y = original_target_position.y
		if (not $RayClimb.is_colliding()) or is_on_floor():
			velocity.y = 0.0
			state = States.FLOOR
			return
	elif Input.is_action_just_pressed("jump") and dir_hori:
		velocity.y = JUMP_VELOCITY/2
		velocity.x = dir_hori * speed
		state = States.AIR
		return

	velocity.y = dir_vert * speed/2

func update_animation_parameters():
	match state:
		States.AIR: # Está no Ar
			state_machine.travel('Jump')
		States.FLOOR: # Está no chão
			if velocity.x != 0.0: # Em movimento no chão
				state_machine.travel('Walk')
			else: # Parado no chão
				if is_duck:
					state_machine.travel('Duck')
				else:
					state_machine.travel('Idle')
		States.CLIMBING: # Está numa corta ou escada
			state_machine.travel('Climb')
			if velocity.normalized().y == 0.0:
				state_machine.stop()
	pass
