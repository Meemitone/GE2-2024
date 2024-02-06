extends CharacterBody3D

@export var max_speed:float = 5
@export var force:Vector3
@export var acceleration:Vector3
@export var target_node_path:NodePath
@export var path:PathFollow3D
@export var mass:float = 1
@export var slowing_distance:float = 1
@export var target_speed:float = 0.05
@export var acceleration_scale:float = 1
var target:Node3D

@export var damping:float = 0.1
@export var banking:float = 0.1

@export var seek_enabled:bool=true
@export var arrive_enabled:bool=false
@export var player_enabled:bool=false

#for banking, we need to calculate an 'effective up' using restitution of force
@export var grav_direction:Vector3 = Vector3(0,-1,0)
@export var grav_scale:float = 3
@export var effective_up:Vector3
var display_bank_force:Vector3
var display_look_dir:Vector3
@export var look_dir:Vector3

var damping:float = 0.1

func draw_gizmos():
	#Red, force
	DebugDraw3D.draw_arrow(global_position, global_position + force, Color.RED, 0.1)
	#Yellow, velocity
	DebugDraw3D.draw_arrow(global_position, global_position + velocity, Color.YELLOW, 0.1)
	#Blue Violet (purps), arrive sphere
	DebugDraw3D.draw_sphere(target.global_position, slowing_distance, Color.CADET_BLUE)
	#green, effective down
	DebugDraw3D.draw_arrow(global_position, global_position + display_bank_force, Color.GREEN, 0.1)
	#orange look dir
	DebugDraw3D.draw_arrow(global_position, global_position + display_look_dir, Color.ORANGE, 0.1)

func _ready():
	target = get_node(target_node_path)	
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING #floating
	
	
func arrive(target_pos:Vector3, slowing:float): 
	var distance = target_pos - global_position
	
	var length = distance.length() #calcing length once rather than twice
	
	var ramped_speed = max_speed*(length/slowing)
	var clipped_speed = min(ramped_speed, max_speed)
	var desired = clipped_speed * distance/length
	return desired - velocity
	
	
func seek(target_pos:Vector3):
	var to_target = target_pos - global_position
	var desired = to_target.normalized() * max_speed
	return desired - velocity
	
func bank(turn_force:Vector3):
	var restitution = -grav_direction * grav_scale # typical "up"
	var derived_up = restitution + turn_force
	display_bank_force = derived_up
	return derived_up.normalized()

func derived_look(up:Vector3, vel:Vector3):
	var right = vel.cross(up)
	var forward = up.cross(right)
	display_look_dir = forward
	return forward

func player():
	return Vector3.ZERO
	pass	
func calculate():
	var force = Vector3.ZERO
	
	if seek_enabled:
		force += seek(target.global_position)
	if arrive_enabled:
		force += arrive(target.global_position, slowing_distance)
	if player_enabled:
		force += player()
	return force

func _physics_process(delta):
	path.progress+=target_speed
	force = arrive(target.global_position, slowing_distance)
	
	force = calculate()
	acceleration = force / mass
	
	velocity = velocity + acceleration * delta * acceleration_scale
	
	effective_up = bank(force)
	look_dir = derived_look(effective_up, velocity)
	if velocity.length() > 0:
		#look_at(global_position - look_dir, effective_up)
		# look_at(position - velocity)
		# apply damping
		velocity -= velocity * delta * damping
					# global_transform.basis.z  = velocity.normalized()
		# global_transform = global_transform.orthonormalized()

		var temp_up = global_transform.basis.y.lerp(Vector3.UP + (acceleration * banking), delta * 5.0)
		look_at(global_transform.origin - velocity.normalized(), temp_up)
	
	move_and_slide()
	draw_gizmos()
	
