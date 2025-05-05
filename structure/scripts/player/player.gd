extends CharacterBody3D

# Movement parameters
@export var walk_speed = 5.0
@export var run_speed = 8.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.002

# Camera control
@onready var camera_mount = $CameraMount
@onready var camera = $CameraMount/Camera3D
@onready var interaction_ray = $CameraMount/RayCast3D

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed = walk_speed

func _ready():
	# Capture the mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# Mouse look control
	if event is InputEventMouseMotion:
		# Rotate the player (body) horizontally
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate the camera mount (head) vertically
		camera_mount.rotate_x(-event.relative.y * mouse_sensitivity)
		# Clamp vertical rotation to prevent over-rotation
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, -PI/2 + 0.1, PI/2 - 0.1)
	
	# Toggle mouse capture with Escape key (helpful during development)
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Add gravity when in the air
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Handle run toggle
	if Input.is_action_pressed("run"):
		current_speed = run_speed
	else:
		current_speed = walk_speed

	# Get input direction vector (2D)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Convert 2D input direction to 3D direction relative to player orientation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply horizontal movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Smooth stop
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Apply the velocity
	move_and_slide()
	
	# Handle interaction
	if Input.is_action_just_pressed("interact"):
		try_interact()

func try_interact():
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider.has_method("interact"):
			collider.interact(self)
			print("Interacting with: ", collider.name)
