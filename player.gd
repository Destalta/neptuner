extends CharacterBody2D
class_name Player

var spawn_point: Vector2
@export var move_speed: float = 15.5
@export var jump_power: float = 250
@onready var sprite: Sprite2D = %Sprite2D
@export var teleport_height: int = 36

var move_input: Vector2 = Vector2.ZERO
var jump_input: bool = false
var jump_cooldown_time: float = 0.1
var jump_cooldowning: bool = false
var coyoting: bool = false
var coyote_time: float = 0.075
var time_grounded: float = 0
var time_ungrounded: float = 0
var max_fall_time: float = 0.75
var teleport_input: bool = false
var teleport_cooldown_time: float = 0.15
var teleport_cooldowning: bool = false

var rot: float = 0

var jump_buffer_time: float = 0.2
var current_jump_buffer_time: float = 0

func _ready() -> void:
	spawn_point = position

func _process(delta: float) -> void:
	if Input.is_action_pressed("move left"):
		move_input.x = -1
	elif Input.is_action_pressed("move right"):
		move_input.x = 1
	else:
		move_input.x = 0
	
	if Input.is_action_just_pressed("jump"):
		current_jump_buffer_time = 0
	
	if Input.is_action_pressed("teleport"):
		teleport_input = true
	else:
		teleport_input = false
	
	if jump_input:
		current_jump_buffer_time += delta
		if current_jump_buffer_time > jump_buffer_time:
			jump_input = false
	
	if Input.is_action_pressed("jump"):
		jump_input = true

func die():
	sprite.visible = false
	show_hitboxes()
	set_process(false)
	set_physics_process(false)
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	var grounded = is_on_floor() or coyoting
	velocity.x = move_speed * 500 * delta
	if grounded:
		time_grounded += delta
		time_ungrounded = 0
		if time_grounded > 0.05:
			sprite.rotation = lerp(sprite.rotation, snappedf(rot, PI / 2.0), 35 * delta)
		if jump_input and !jump_cooldowning:
			jump_cooldowning = true
			get_tree().create_timer(jump_cooldown_time).timeout.connect(func(): jump_cooldowning = false)
			velocity.y = -jump_power
	else:
		rot += 5 * delta
		sprite.rotation = lerp(sprite.rotation, rot, 55 * delta)
		time_grounded = 0
		time_ungrounded += delta
		velocity += get_gravity() * delta
	
	if teleport_input and !teleport_cooldowning:
		teleport_cooldowning = true
		get_tree().create_timer(teleport_cooldown_time).timeout.connect(func(): teleport_cooldowning = false)
		position.y -= teleport_height
		velocity.y = 0
	
	if is_on_wall():
		die()
	
	if is_on_ceiling():
		die()
	
	if time_ungrounded >= max_fall_time:
		die()
	
	move_and_slide()

func create_rect(rect: Rect2) -> Sprite2D:
	var rect_sprite: Sprite2D = Sprite2D.new()
	var tex: Texture2D = load("res://hitbox.png")
	rect_sprite.texture = tex 
	rect_sprite.scale = rect.size / tex.get_size() 
	rect_sprite.position = rect.position + (rect.size / 2.0)
	rect_sprite.self_modulate = Color.RED
	rect_sprite.z_index = 99
	get_tree().current_scene.add_child(rect_sprite)
	return rect_sprite

func show_hitboxes():
	for node in get_tree().current_scene.find_children("*", "CollisionShape2D", true, false):
		var local_rect: Rect2 = node.get_shape().get_rect()
		var global_rect: Rect2 = node.get_parent().transform * local_rect
		create_rect(global_rect)
