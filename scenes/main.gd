# File: main.gd

extends Node

@export var snake_scene: PackedScene

const ObstacleScene = preload("res://scenes/obstacle.tscn")
const FoodScene = preload("res://scenes/food.tscn")
const NextLevelScreenScene = preload("res://scenes/nextlevel.tscn")

var food_data = {
	"apple": { "score": 10, "texture": preload("res://assets/apple.png") },
	"banana": { "score": 15, "texture": preload("res://assets/banana.png") },
	"diamond": { "score": 100, "texture": preload("res://assets/diamonds.png") }
}

var level_data = [
	{ "level": 1, "goal": 5, "speed": 0.25, "obstacles": [] },
	{ "level": 2, "goal": 8, "speed": 0.20, "obstacles": [ Vector2(5, 9), Vector2(6, 9), Vector2(7, 9), Vector2(8, 9), Vector2(11, 9), Vector2(12, 9), Vector2(13, 9), Vector2(14, 9) ]},
	{ "level": 3, "goal": 10, "speed": 0.15, "obstacles": [ Vector2(0, 5), Vector2(1, 5), Vector2(2, 5), Vector2(3, 5), Vector2(4, 5), Vector2(15, 14), Vector2(16, 14), Vector2(17, 14), Vector2(18, 14), Vector2(19, 14) ]}
]

# Variabel Game & Level
var score: int
var game_started: bool = false
var food_was_eaten: bool = false
var current_level_index: int = 0
var food_eaten_this_level: int = 0
var current_level_obstacles: Array = []

# Variabel Grid
var cells: int = 20
var cell_size: int = 50

# Variabel Ular
var snake_data: Array = []
var snake_nodes: Array = []
var old_snake_data: Array = []
var current_food_position: Vector2

# Variabel Gerakan
var start_pos = Vector2(9, 9)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var move_direction: Vector2
var can_change_direction: bool = true

# Referensi ke UI
@onready var game_over_menu = $GameOverMenu
@onready var hud = $Hud
@onready var move_timer = $MoveTimer
var next_level_screen: CanvasLayer

func _ready():
	next_level_screen = NextLevelScreenScene.instantiate()
	add_child(next_level_screen)
	next_level_screen.proceed_to_next_level.connect(_on_next_level_screen_proceed_to_next_level)
	new_game()

# --- FUNGSI UTAMA GAME ---
func new_game():
	current_level_index = 0
	score = 0
	game_over_menu.hide()
	get_tree().paused = false
	_start_level()

func _start_level():
	# Hapus semua sisa dari level sebelumnya
	get_tree().call_group("segments", "queue_free")
	get_tree().call_group("obstacles", "queue_free")
	var existing_food = find_child("Food", false, false)
	if is_instance_valid(existing_food):
		existing_food.queue_free()

	next_level_screen.hide()
	
	# Reset variabel level
	food_eaten_this_level = 0
	game_started = false
	can_change_direction = true
	move_direction = up # Mulai dengan arah default ke atas
	
	var level = level_data[current_level_index]
	move_timer.wait_time = level["speed"]
	
	_update_hud()
	
	generate_snake()
	_spawn_obstacles()
	call_deferred("_spawn_food")

func end_game():
	move_timer.stop()
	game_over_menu.show()
	get_tree().paused = true

# --- FUNGSI INPUT PEMAIN ---
func _input(event):
	# Abaikan input jika game di-pause
	if get_tree().paused:
		return

	# Tentukan arah baru berdasarkan tombol yang ditekan
	var new_direction = move_direction
	if event.is_action_pressed("move_down") and move_direction != up:
		new_direction = down
	elif event.is_action_pressed("move_up") and move_direction != down:
		new_direction = up
	elif event.is_action_pressed("move_left") and move_direction != right:
		new_direction = left
	elif event.is_action_pressed("move_right") and move_direction != left:
		new_direction = right

	# Logika untuk memulai game dengan gerakan pertama
	if not game_started and new_direction != move_direction:
		move_direction = new_direction
		start_game()
	# Logika untuk mengubah arah saat game sudah berjalan
	elif game_started and can_change_direction and new_direction != move_direction:
		move_direction = new_direction
		can_change_direction = false # Kunci input sampai frame gerakan berikutnya

func start_game():
	game_started = true
	move_timer.start()

# --- FUNGSI GERAKAN ULAR (dijalankan oleh Timer) ---
func _on_move_timer_timeout():
	can_change_direction = true # Buka kunci input agar pemain bisa mengubah arah lagi
	
	old_snake_data = [] + snake_data # Buat salinan posisi ular sebelumnya
	
	# Gerakkan kepala ular
	snake_data[0] += move_direction
	
	# Buat seluruh tubuh mengikuti kepala
	for i in range(1, len(snake_data)):
		snake_data[i] = old_snake_data[i - 1]
	
	# Perbarui posisi visual dari setiap segmen ular
	for i in range(len(snake_nodes)):
		if is_instance_valid(snake_nodes[i]):
			snake_nodes[i].position = snake_data[i] * cell_size

	# Lakukan semua pengecekan
	check_collisions()

# --- FUNGSI PENGECEKAN (Collision, dll) ---
func check_collisions():
	var head_pos = snake_data[0]
	
	# Cek tabrakan dengan batas layar
	if head_pos.x < 0 or head_pos.x >= cells or head_pos.y < 0 or head_pos.y >= cells:
		end_game()
		return # Hentikan pengecekan lebih lanjut jika sudah game over

	# Cek tabrakan dengan tubuh sendiri
	for i in range(1, len(snake_data)):
		if head_pos == snake_data[i]:
			end_game()
			return
			
	# Cek tabrakan dengan rintangan
	if head_pos in current_level_obstacles:
		end_game()
		return
		
	# Cek apakah memakan makanan
	if head_pos == current_food_position:
		eat_food()

# --- FUNGSI PEMBANTU LAINNYA (Spawn, HUD, dll) ---
func eat_food():
	var food_node = find_child("Food", false, false)
	if is_instance_valid(food_node):
		score += food_node.score
		food_node.queue_free()
	
	add_segment(old_snake_data[-1])
	food_was_eaten = true # Beri tanda untuk spawn makanan baru
	
	food_eaten_this_level += 1
	_update_hud()
	
	var level = level_data[current_level_index]
	if food_eaten_this_level >= level["goal"]:
		var completed_level_number = level["level"]
		current_level_index += 1
		if current_level_index >= len(level_data):
			print("GAME TAMAT!")
			end_game()
		else:
			get_tree().paused = true
			next_level_screen.show_screen(completed_level_number)
			
	if food_was_eaten:
		_spawn_food()
		food_was_eaten = false

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
			end_game()
			return

	for i in range(3):
		add_segment(safe_start_pos + Vector2(0, i))

func add_segment(pos):
	if snake_scene == null:
		push_error("Snake Scene belum diatur di editor!")
		get_tree().quit()
		return
	
	snake_data.append(pos)
	var snake_segment = snake_scene.instantiate()
	snake_segment.position = pos * cell_size
	snake_segment.add_to_group("segments")
	add_child(snake_segment)
	snake_nodes.append(snake_segment) # Simpan referensi node nya

func _spawn_obstacles():
	# (Fungsi ini tidak perlu diubah, sama seperti sebelumnya)
	current_level_obstacles.clear()
	var obstacles_pos_array = level_data[current_level_index]["obstacles"]
	for pos in obstacles_pos_array:
		var obstacle_instance = ObstacleScene.instantiate()
		obstacle_instance.position = pos * cell_size
		obstacle_instance.add_to_group("obstacles")
		add_child(obstacle_instance)
		current_level_obstacles.append(pos)
		
func _spawn_food():
	# (Fungsi ini tidak perlu diubah, sama seperti sebelumnya)
	var possible_positions = []
	for x in range(cells):
		for y in range(cells):
			var potential_pos = Vector2(x, y)
			if not potential_pos in snake_data and not potential_pos in current_level_obstacles:
				possible_positions.append(potential_pos)

	if possible_positions.is_empty():
		end_game()
		return

	var food_types = food_data.keys()
	if food_types.is_empty():
		end_game()
		return

	var random_food_name = food_types[randi() % food_types.size()]
	var selected_food_data = food_data[random_food_name]
	
	current_food_position = possible_positions[randi() % possible_positions.size()]
	
	var food_instance = FoodScene.instantiate()
	food_instance.name = "Food"
	add_child(food_instance)
	
	food_instance.setup(random_food_name, selected_food_data["score"], selected_food_data["texture"], cell_size)
	food_instance.position = current_food_position * cell_size

func _update_hud():
	# (Fungsi ini tidak perlu diubah, sama seperti sebelumnya)
	var level = level_data[current_level_index]
	hud.get_node("LevelLabel").text = "Level: " + str(level["level"])
	if hud.has_node("GoalLabel"):
		hud.get_node("GoalLabel").text = "Tujuan: " + str(food_eaten_this_level) + " / " + str(level["goal"])
	hud.get_node("ScoreLabel").text = "SKOR: " + str(score)

func _on_game_over_menu_restart():
	new_game()

func _on_next_level_screen_proceed_to_next_level():
	get_tree().paused = false
	_start_level()
