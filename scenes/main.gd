# File: main.gd (VERSI LENGKAP DAN BENAR)
extends Node

const ObstacleScene = preload("res://scenes/obstacle.tscn")
const FoodScene = preload("res://scenes/food.tscn")
const NextLevelScreenScene = preload("res://scenes/nextlevel.tscn")
const snake_scene = preload("res://scenes/snake_segment.tscn")
const EAT_SFX = preload("res://audio/crunch.wav")

var food_data = {
	"apple": { "score": 10, "texture": preload("res://assets/apple.png") },
	"banana": { "score": 15, "texture": preload("res://assets/banana.png") },
	"diamond": { "score": 100, "texture": preload("res://assets/diamonds.png") },
	"grape": { "score": 20, "texture": preload("res://assets/grape.png") },
	"pear": { "score": 25, "texture": preload("res://assets/pear.png") }
}

# Ganti variabel level_data Anda dengan ini untuk contoh yang lebih kompleks

var level_data = [
	# LEVEL 1: Kosong, untuk pemanasan
	{ "level": 1, "goal": 5, "speed": 0.25, "obstacles": [] },
	
	# LEVEL 2: Dua dinding horizontal
	{ "level": 2, "goal": 8, "speed": 0.20, "obstacles": [ 
		Vector2(5, 9), Vector2(6, 9), Vector2(7, 9), Vector2(8, 9), 
		Vector2(11, 9), Vector2(12, 9), Vector2(13, 9), Vector2(14, 9) 
		]
	},
	
	# LEVEL 3: Dua dinding di pojok
	{ "level": 3, "goal": 10, "speed": 0.15, "obstacles": [ 
		Vector2(0, 5), Vector2(1, 5), Vector2(2, 5), Vector2(3, 5), Vector2(4, 5), 
		Vector2(15, 14), Vector2(16, 14), Vector2(17, 14), Vector2(18, 14), Vector2(19, 14) 
		]
	},
	
# LEVEL 4 (MODIFIKASI): Kotak Terbuka
	{ "level": 4, "goal": 12, "speed": 0.15, "obstacles": [
		# Dinding atas, dengan celah di tengah
		Vector2(7, 7), Vector2(8, 7),    # Bagian kiri atas
		Vector2(11, 7), Vector2(12, 7),  # Bagian kanan atas
		
		# Dinding bawah, dengan celah di tengah
		Vector2(7, 12), Vector2(8, 12),  # Bagian kiri bawah
		Vector2(11, 12), Vector2(12, 12),# Bagian kanan bawah
		
		# Dinding kiri, dengan celah di tengah
		Vector2(7, 8), Vector2(7, 9),    # Bagian atas kiri
		Vector2(7, 10), Vector2(7, 11),  # Bagian bawah kiri
		
		# Dinding kanan, dengan celah di tengah
		Vector2(12, 8), Vector2(12, 9),  # Bagian atas kanan
		Vector2(12, 10), Vector2(12, 11) # Bagian bawah kanan
		]
	},

	# LEVEL 5 (BARU): Pola Pagar
	{ "level": 5, "goal": 15, "speed": 0.12, "obstacles": [
		Vector2(4, 0), Vector2(4, 1), Vector2(4, 2), Vector2(4, 3), Vector2(4, 4), Vector2(4, 5), Vector2(4, 6),
		Vector2(9, 19), Vector2(9, 18), Vector2(9, 17), Vector2(9, 16), Vector2(9, 15), Vector2(9, 14), Vector2(9, 13),
		Vector2(14, 0), Vector2(14, 1), Vector2(14, 2), Vector2(14, 3), Vector2(14, 4), Vector2(14, 5), Vector2(14, 6)
		]
	},
	
	# LEVEL 6 (BARU): Labirin Sederhana
	{ "level": 6, "goal": 20, "speed": 0.10, "obstacles": [
		# Dinding pembatas luar
		Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0), Vector2(5, 0), Vector2(6, 0), Vector2(7, 0),
		Vector2(19, 19), Vector2(18, 19), Vector2(17, 19), Vector2(16, 19), Vector2(15, 19), Vector2(14, 19), Vector2(13, 19), Vector2(12, 19),
		# Dinding dalam
		Vector2(7, 5), Vector2(8, 5), Vector2(9, 5), Vector2(10, 5), Vector2(11, 5), Vector2(12, 5),
		Vector2(12, 6), Vector2(12, 7), Vector2(12, 8),
		Vector2(7, 14), Vector2(8, 14), Vector2(9, 14), Vector2(10, 14), Vector2(11, 14), Vector2(12, 14),
		Vector2(7, 13), Vector2(7, 12), Vector2(7, 11)
		]
	}
]

var score: int = 0
var game_started: bool = false
var current_level_index: int = 0
var food_eaten_this_level: int = 0
var current_level_obstacles: Array = []

var cells: int = 20
var cell_size: int = 50

var snake_data: Array[Vector2] = []
var snake_nodes: Array[Node2D] = []
var old_snake_data: Array[Vector2] = []

var start_pos = Vector2(9, 9)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var move_direction: Vector2
var can_change_direction: bool = true
var is_in_transition: bool = false

@onready var game_over_menu = $GameOverMenu
@onready var hud = $Hud
@onready var move_timer = $MoveTimer
var next_level_screen: CanvasLayer
var current_food: Area2D

func _ready():
	AudioManager.play_music()
	next_level_screen = NextLevelScreenScene.instantiate()
	add_child(next_level_screen)
	next_level_screen.proceed_to_next_level.connect(_on_next_level_screen_proceed_to_next_level)

	game_over_menu.restart.connect(_on_game_over_menu_restart)

	new_game()

func new_game():
	current_level_index = 0
	score = 0
	hud.get_node("ScoreLabel").text = "SKOR: " + str(score)
	game_over_menu.hide()
	get_tree().paused = false
	_start_level()

func _start_level():
	get_tree().call_group("segments", "queue_free")
	get_tree().call_group("obstacles", "queue_free")
	if is_instance_valid(current_food):
		current_food.queue_free()

	next_level_screen.hide()
	
	is_in_transition = false
	food_eaten_this_level = 0
	game_started = false
	can_change_direction = true
	move_direction = up

	var level = level_data[current_level_index]
	move_timer.wait_time = level["speed"]

	_update_hud()

	_spawn_obstacles()
	generate_snake()
	call_deferred("_spawn_food")

func end_game():
	move_timer.stop()
	game_over_menu.show()
	get_tree().paused = true

func _input(event):
	if is_in_transition:
		return

	if get_tree().paused:
		return

	var new_direction = move_direction
	if event.is_action_pressed("move_down") and move_direction != up:
		new_direction = down
	elif event.is_action_pressed("move_up") and move_direction != down:
		new_direction = up
	elif event.is_action_pressed("move_left") and move_direction != right:
		new_direction = left
	elif event.is_action_pressed("move_right") and move_direction != left:
		new_direction = right

	if not game_started and new_direction != move_direction:
		move_direction = new_direction
		start_game()
	elif game_started and can_change_direction and new_direction != move_direction:
		move_direction = new_direction
		can_change_direction = false

func start_game():
	game_started = true
	move_timer.start()

func _on_move_timer_timeout():
	can_change_direction = true
	old_snake_data = snake_data.duplicate()

	snake_data[0] += move_direction

	for i in range(1, len(snake_data)):
		snake_data[i] = old_snake_data[i - 1]

	for i in range(len(snake_nodes)):
		if is_instance_valid(snake_nodes[i]):
			snake_nodes[i].position = snake_data[i] * cell_size

	check_collisions()

func check_collisions():
	var head_pos = snake_data[0]

	if head_pos.x < 0 or head_pos.x >= cells or head_pos.y < 0 or head_pos.y >= cells:
		end_game()
		return

	if head_pos in snake_data.slice(1):
		end_game()
		return

	if head_pos in current_level_obstacles:
		end_game()
		return

	if is_instance_valid(current_food) and head_pos == current_food.grid_position:
		eat_food()

func eat_food():
	AudioManager.play_sfx(EAT_SFX)
	if not is_instance_valid(current_food): return

	score += current_food.score
	current_food.queue_free()

	add_segment(old_snake_data.back())

	food_eaten_this_level += 1
	_update_hud()

	var level = level_data[current_level_index]
	if food_eaten_this_level >= level["goal"]:
		_level_complete()
	else:
		call_deferred("_spawn_food")

func _level_complete():
	get_tree().paused = true
	move_timer.stop()
	var completed_level_number = level_data[current_level_index]["level"]
	current_level_index += 1

	if current_level_index >= len(level_data):
		print("SELURUH LEVEL TAMAT!")
		end_game()
	else:
		next_level_screen.show_screen(completed_level_number)

func generate_snake():
	for segment_node in snake_nodes:
		if is_instance_valid(segment_node):
			segment_node.queue_free()
	snake_nodes.clear()
	snake_data.clear()
	old_snake_data.clear()

	var safe_start_pos = start_pos
	while safe_start_pos in current_level_obstacles:
		safe_start_pos.y -= 1
		if safe_start_pos.y < 0:
			push_error("Tidak ada posisi awal yang aman!")
			end_game()
			return

	for i in range(3):
		add_segment(safe_start_pos + Vector2(0, i))

func add_segment(pos: Vector2):
	snake_data.append(pos)
	var snake_segment = snake_scene.instantiate()
	snake_segment.position = pos * cell_size
	snake_segment.add_to_group("segments")
	add_child(snake_segment)
	snake_nodes.append(snake_segment)

func _spawn_obstacles():
	current_level_obstacles.clear()
	var obstacles_pos_array = level_data[current_level_index]["obstacles"]
	for pos in obstacles_pos_array:
		var obstacle_instance = ObstacleScene.instantiate()
		obstacle_instance.position = pos * cell_size
		obstacle_instance.add_to_group("obstacles")
		add_child(obstacle_instance)
		current_level_obstacles.append(pos)

func _spawn_food():
	var possible_positions = []
	for x in range(cells):
		for y in range(cells):
			var potential_pos = Vector2(x, y)
			if not potential_pos in snake_data and not potential_pos in current_level_obstacles:
				possible_positions.append(potential_pos)

	if possible_positions.is_empty():
		print("Tidak ada tempat lagi! Level Selesai!")
		_level_complete() # <-- INI SOLUSINYA
		return


	var food_types = food_data.keys()
	var random_food_name = food_types[randi() % food_types.size()]
	var selected_food_data = food_data[random_food_name]

	var food_grid_pos = possible_positions.pick_random()

	var food_instance = FoodScene.instantiate()
	current_food = food_instance 
	current_food.grid_position = food_grid_pos
	add_child(current_food)

	current_food.setup(random_food_name, selected_food_data["score"], selected_food_data["texture"], cell_size)
	current_food.position = food_grid_pos * cell_size

func _update_hud():
	var level = level_data[current_level_index]
	hud.get_node("LevelLabel").text = "Level: " + str(level["level"])
	if hud.has_node("GoalLabel"):
		hud.get_node("GoalLabel").text = "Tujuan: " + str(food_eaten_this_level) + " / " + str(level["goal"])
	hud.get_node("ScoreLabel").text = "SKOR: " + str(score)

func _on_game_over_menu_restart():
	get_tree().paused = false
	new_game()

func _on_next_level_screen_proceed_to_next_level():
	get_tree().paused = false
	_start_level() # Langsung mulai level berikutnya
