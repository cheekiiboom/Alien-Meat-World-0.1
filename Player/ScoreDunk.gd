extends Area3D

@onready var collision = %CollisionShape3D
@onready var dunk_target = %Player
@onready var animation_dunkOrb = %Animation_scoreDunk
@onready var animation_scoreCount = %Animation_scoreCount
@onready var mesh = %MeshInstance3D
@onready var score_count = %scoreCount

# Adjust these together!!
var dunk_y_offset: float = 6.1
const DUNK_Y_OFFSET = 6.1

@export var dunk_ascent_distance: float = 1.6

# Cam Movement vars
@export var dunk_lerpspeed = .05
@export var dunk_z_offset = 0.0
@export var dunk_x_offset = 0.0

var is_grabbing = false
var something_in_dunk = false
var dunked_meat
var score_update = 0
var dunked_meats_in_group

@onready var dunk_ascent_timer : Timer = Timer.new()
const DUNK_ASCENT_TIMER_DURATION = 2.0
var dunk_ascent_timer_duration = 2.0

@export var dunk_2d_pos = Vector2(580,150)
const DUNK_MAX_OPACITY_DISTANCE := 200.0


# Called when the node enters the scene tree for the first time.
func _ready():
	set_collision_mask_value(4, true)
	
	$VisibleOnScreenNotifier3D.screen_exited.connect(on_screen_exited)
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)
	Messenger.grab_begun.connect(on_grab_begun)
	Messenger.grab_ended.connect(on_grab_ended)
	Messenger.meat_in_dunk.connect(on_meat_in_dunk)
	
	dunk_ascent_timer.timeout.connect(on_ascent_timer_timeout)
	dunk_ascent_timer.one_shot = true
	add_child(dunk_ascent_timer)

	
func _physics_process(delta):
#	print(score)
# Beautiful mouse-position-based transparency code that turned out maybe isn't useful here...
#	var mouse_pos = get_viewport().get_mouse_position()
#	var dunk_distance_from_mouse = dunk_2d_pos.distance_to(mouse_pos)
#	var dunk_opacity = clamp(1 - dunk_distance_from_mouse / DUNK_MAX_OPACITY_DISTANCE, 0.3, 0.7)
#	print(dunk_opacity)
#
#	mesh.set_transparency(dunk_opacity)


	dunked_meats_in_group = get_tree().get_nodes_in_group("Dunked").size()
#	print(score_update)
	score_update = dunked_meats_in_group
	score_count.text = str("+",score_update)


		
	
	
	
	# Dunk descent
	if is_grabbing and dunk_y_offset == DUNK_Y_OFFSET:
#		dunk_ascent_timer_duration = DUNK_ASCENT_TIMER_DURATION
		dunk_ascent_timer.start(dunk_ascent_timer_duration)
		dunk_y_offset -= dunk_ascent_distance
		
#	if !is_grabbing and dunk_y_offset < DUNK_Y_OFFSET:
#
		
	# Dunk follow position
	var dunk_follow_pos: Vector3 = dunk_target.position
#	dunk_follow_pos.z += dunk_z_offset
	dunk_follow_pos.y += dunk_y_offset
	dunk_follow_pos.x += dunk_x_offset

	# Dunk Follow Normalize
	var dunk_direction: Vector3 = dunk_follow_pos - self.position

	self.position += dunk_direction * dunk_lerpspeed

	# Dunk visibility
#	print("Dunk: ", "Y offset= ", dunk_y_offset, ". Y const= ", DUNK_Y_OFFSET, ". Y follow pos= ", self.position.y)

		
	var dunk_position = self.global_position
	Messenger.dunk_is_at_position.emit(dunk_position)
		
func on_ascent_timer_timeout():
	dunk_y_offset += dunk_ascent_distance
	
func on_screen_exited():
	# If dunked_meat is not null
	if !dunked_meat == null:
		# Possible combo stuff?
#		if dunked_meats_in_group >= 2:
#			score_update = dunked_meats_in_group * 2
#		if dunked_meats_in_group == 1:
#			score_update = dunked_meats_in_group
		
		Messenger.abduction.emit(score_update)
		score_update = 0

		for meat in get_tree().get_nodes_in_group("Dunked"):
			meat.queue_free()
#		score = 0
		
		# Check dunked meat variables here? Eg:
		if !dunked_meat.empathy_ok:
			pass

func on_grab_begun():
	is_grabbing = true
#	collision.disabled = false
	
func on_grab_ended():
	is_grabbing = false
#	collision.disabled = true

func on_body_entered(body):
	if body.is_in_group("Grabbed"):
		Messenger.meat_entered_dunk.emit(body)
		animation_dunkOrb.play("hover_throb")

func on_body_exited(body):
	if body.is_in_group("Meat"):
		Messenger.meat_left_dunk.emit(body)
		animation_dunkOrb.play("base_size", .2)
		
func on_meat_in_dunk(dunked):
	dunked_meat = dunked
	animation_scoreCount.stop()
	animation_scoreCount.play("score_up")