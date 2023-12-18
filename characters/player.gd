extends CharacterBody2D

enum States {FLOOR, AIR, CLIMBING, ATTACKING}
@export var speed : float = 300.0
const JUMP_VELOCITY = -600.0
var state: States = States.AIR
var is_duck: bool = false
var original_target_position
var state_machine
var look_at = Vector2(1,0)
var can_attack = true

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
	if dir_hori != 0 and look_at.x != dir_hori:
		if state != States.ATTACKING:
			look_at = Vector2(dir_hori, 0)
	match state:
		States.FLOOR:
			floor_state(delta, dir_hori, dir_vert)
		States.AIR:
			air_state(delta, dir_hori, dir_vert)
		States.CLIMBING:
			climbing_state(delta, dir_hori, dir_vert)
		States.ATTACKING:
			attacking_state(delta, dir_hori, dir_vert)
		
	move_and_slide()

func floor_state(_delta, dir_hori, dir_vert):
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
	elif Input.is_action_just_pressed("attack") and can_attack:
		$TimerAttack.start(0.5)
		can_attack = false
		state = States.ATTACKING
		velocity = Vector2.ZERO
		return
		
	if dir_hori:
		if is_duck: is_duck = false
		velocity.x = dir_hori * speed
	else:
		velocity.x =  move_toward(velocity.x, 0, speed)
	
func air_state(delta, dir_hori, dir_vert):
	if is_on_floor():
		state = States.FLOOR
		return
	elif $RayClimb.is_colliding() and dir_vert == -1:
		state = States.CLIMBING
		velocity.x = 0.0
		var tile_map:TileMap = $RayClimb.get_collider()
		position.x = tile_map.map_to_local(tile_map.local_to_map($RayClimb.get_collision_point())).x
		return
		
	if Input.is_action_just_pressed("attack") and can_attack:
		$TimerAttack.start(0.4)
		can_attack = false
		state = States.ATTACKING
		return
	
	velocity.y += gravity * delta
	
	if dir_hori:
		velocity.x = dir_hori * speed
	else:
		velocity.x =  move_toward(velocity.x, 0, speed)
	
func climbing_state(_delta, dir_hori, dir_vert):
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

func attacking_state(delta, _dir_hori, _dir_vert):
	if not is_on_floor():
		velocity.y += gravity * delta

func update_animation_parameters():
	match state:
		States.AIR: # Está no Ar
			state_machine.travel('Jump')
			animation_tree["parameters/Jump/blend_position"] = look_at.normalized()
		States.FLOOR: # Está no chão
			if velocity.x != 0.0: # Em movimento no chão
				state_machine.travel('Walk')
				animation_tree["parameters/Walk/blend_position"] = look_at.normalized()
			else: # Parado no chão
				if is_duck:
					state_machine.travel('Duck')
					animation_tree["parameters/Duck/blend_position"] = look_at.normalized()
				else:
					state_machine.travel('Idle')
					animation_tree["parameters/Idle/blend_position"] = look_at.normalized()
		States.CLIMBING: # Está numa corta ou escada
			state_machine.travel('Climb')
			if velocity.normalized().y == 0.0:
				state_machine.stop()
		States.ATTACKING: # Está atacando
			state_machine.travel('Attack')
			animation_tree["parameters/Attack/blend_position"] = look_at.normalized()
	pass

func attack_animation_finished():
	if is_on_floor():
		state = States.FLOOR
	else:
		state = States.AIR

func _on_timer_attack_timeout():
	can_attack = true
	pass
