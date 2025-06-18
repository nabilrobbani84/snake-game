extends Node

@export var snake_scene: PackedScene # Pastikan ini terisi di editor Godot!

# Pastikan kedua scene ini ada di folder /scenes
const ObstacleScene = preload("res://scenes/obstacle.tscn")
const FoodScene = preload("res://scenes/food.tscn")
const NextLevelScreenScene = preload("res://scenes/next_level_screen.tscn") # Tambahkan preload ini

var food_data = {
	"apple": { "score": 10, "texture": preload("res://assets/apple.png") },
	"banana": { "score": 15, "texture": preload("res://assets/banana.png") },
	"diamond": { "score": 100, "texture": preload("res://assets/diamonds.png") }
}

var level_data = [
	{
		"level": 1, "goal": 5, "speed": 0.25, "obstacles": []
	},
	{
		"level": 2, "goal": 8, "speed": 0.20, "obstacles": [
			Vector2(5, 9), Vector2(6, 9), Vector2(7, 9), Vector2(8, 9),
			Vector2(11, 9), Vector2(12, 9), Vector2(13, 9), Vector2(14, 9)
		]
	},
	{
		"level": 3, "goal": 10, "speed": 0.15, "obstacles": [
			Vector2(0, 5), Vector2(1, 5), Vector2(2, 5), Vector2(3, 5), Vector2(4, 5),
			Vector2(15, 14), Vector2(16, 14), Vector2(17, 14), Vector2(18, 14), Vector2(19, 14)
		]
	}
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
var old_data: Array = []
var snake_data: Array = []
var snake: Array = [] # Menyimpan referensi ke node ular
var current_food_position: Vector2

# Variabel Gerakan
var start_pos = Vector2(9, 9)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var move_direction: Vector2
var can_change_direction: bool = true # Changed from can_move for clarity

# Referensi ke UI elemen
@onready var game_over_menu = $GameOverMenu
@onready var hud = $Hud
@onready var move_timer = $MoveTimer
var next_level_screen: CanvasLayer # Deklarasikan variabel untuk next_level_screen

func _ready():
	# Instance next_level_screen dan tambahkan ke pohon scene
	next_level_screen = NextLevelScreenScene.instantiate()
	add_child(next_level_screen)
	# Hubungkan sinyal dari next_level_screen
	next_level_screen.proceed_to_next_level.connect(_on_next_level_screen_proceed_to_next_level)
	new_game()

func new_game():
	current_level_index = 0
	score = 0
	game_over_menu.hide()
	get_tree().paused = false
	_start_level()

#---------------------------------
# Fungsi Manajemen Level
#---------------------------------

func _start_level():
	get_tree().call_group("segments", "queue_free")
	get_tree().call_group("obstacles", "queue_free")
	# Check if "Food" node exists before attempting to free it
	if has_node("Food"):
		get_node("Food").queue_free()
	
	next_level_screen.hide() # Pastikan next level screen tersembunyi
	
	food_eaten_this_level = 0
	game_started = false
	can_change_direction = true # Reset for new level
	move_direction = up # Start with default direction
	
	var level = level_data[current_level_index]
	move_timer.wait_time = level["speed"]
	print("Level ", level["level"], " started. Speed: ", level["speed"])
	
	_update_hud()
	
	generate_snake()
	_spawn_obstacles()
	call_deferred("_spawn_food")

func _spawn_obstacles():
	current_level_obstacles.clear()
	var obstacles_pos_array = level_data[current_level_index]["obstacles"]
	for pos in obstacles_pos_array:
		var obstacle_instance = ObstacleScene.instantiate()
		# Adjust position: obstacles typically align with the grid cell, 
		# so no need to add cell_size to Y unless your textures are offset.
		# If your textures are anchored top-left and cell_size is height, it's correct.
		obstacle_instance.position = (pos * cell_size) # Check your obstacle scene's origin/pivot
		obstacle_instance.add_to_group("obstacles")
		add_child(obstacle_instance)
		current_level_obstacles.append(pos)

func _update_hud():
	var level = level_data[current_level_index]
	hud.get_node("LevelLabel").text = "Level: " + str(level["level"])
	# Pastikan GoalLabel ada di Hud scene Anda
	if hud.has_node("GoalLabel"):
		hud.get_node("GoalLabel").text = "Tujuan: " + str(food_eaten_this_level) + " / " + str(level["goal"])
	hud.get_node("ScoreLabel").text = "SKOR: " + str(score)

#---------------------------------
# Fungsi Inti Permainan
#---------------------------------

func generate_snake():
	old_data.clear()
	snake_data.clear()
	# Penting: Kosongkan array snake yang menyimpan referensi ke node ular
	for segment_node in snake:
		if is_instance_valid(segment_node):
			segment_node.queue_free()
	snake.clear()

	var safe_start_pos = start_pos
	# Pastikan posisi awal ular tidak menimpa obstacle
	# This loop might cause an infinite loop if the map is completely filled around start_pos
	# Consider a more robust check or ensure maps always have clear start spots.
	while safe_start_pos in current_level_obstacles:
		safe_start_pos += Vector2(0, -1) # Sesuaikan arah jika perlu
		if safe_start_pos.y < 0: # Prevent going off-grid indefinitely
			safe_start_pos = start_pos + Vector2(1,0) # Try another direction
			if safe_start_pos.x >= cells: # If all directions around start are blocked, this needs a better solution.
				push_error("Snake start position blocked and no alternative found!")
				end_game() # Or handle this more gracefully
				return
	
	for i in range(3):
		add_segment(safe_start_pos + Vector2(0, i))
	# Ensure the snake's initial position is also added to current_level_obstacles to prevent food spawning on top
	# This might need to be rethought depending on how you want to handle initial snake body blocking food
	# For now, food spawn logic already checks snake_data, so this might not be strictly necessary here.

func add_segment(pos):
	if snake_scene == null:
		# Ini adalah pesan debug penting jika Anda lupa mengisi snake_scene di editor
		push_error("Snake Scene belum diatur di editor! Silakan seret snake_segment.tscn ke slot Snake Scene di Inspector.")
		return
	
	snake_data.append(pos)
	var SnakeSegment = snake_scene.instantiate()
	SnakeSegment.position = (pos * cell_size) # Adjust for cell_size if your textures are top-left anchored.
	SnakeSegment.add_to_group("segments")
	add_child(SnakeSegment)
	snake.append(SnakeSegment)

func _input(event):
	if get_tree().paused or not game_started: return

	if event.is_action_pressed("move_down") and move_direction != up and can_change_direction:
		move_direction = down
		can_change_direction = false
	elif event.is_action_pressed("move_up") and move_direction != down and can_change_direction:
		move_direction = up
		can_change_direction = false
	elif event.is_action_pressed("move_left") and move_direction != right and can_change_direction:
		move_direction = left
		can_change_direction = false
	elif event.is_action_pressed("move_right") and move_direction != left and can_change_direction:
		move_direction = right
		can_change_direction = false
	
	if not game_started and not can_change_direction: # If direction was changed, start the game
		start_game()

# Removed _process(_delta): move_snake()
# Movement is now solely controlled by the timer, and input changes direction.

func start_game():
	game_started = true
	move_timer.start()

func _on_move_timer_timeout():
	# Allow direction change for the next movement frame
	can_change_direction = true
	
	old_data = [] + snake_data # Buat salinan
	
	# Perbarui posisi kepala ular
	snake_data[0] += move_direction
	
	# Perbarui posisi segmen tubuh ular
	for i in range(len(snake_data)):
		if i > 0:
			snake_data[i] = old_data[i - 1]
		# Pastikan node ular masih valid sebelum memperbarui posisinya
		if i < snake.size() and is_instance_valid(snake[i]):
			snake[i].position = (snake_data[i] * cell_size) # Adjust for cell_size if your textures are top-left anchored.
	
	check_out_of_bounds()
	if not get_tree().paused: # Only check if game is not already over by out_of_bounds
		check_self_eaten()
	if not get_tree().paused:
		check_obstacle_collision()
	if not get_tree().paused:
		check_food_eaten()
	
	if food_was_eaten:
		print("--- Flag 'food_was_eaten' is true. Calling _spawn_food().")
		_spawn_food()
		food_was_eaten = false

func check_obstacle_collision():
	if snake_data[0] in current_level_obstacles:
		end_game()
		
func check_out_of_bounds():
	if snake_data[0].x < 0 or snake_data[0].x >= cells or snake_data[0].y < 0 or snake_data[0].y >= cells:
		end_game()

func check_self_eaten():
	for i in range(1, len(snake_data)):
		if snake_data[0] == snake_data[i]:
			end_game()

func check_food_eaten():
	if snake_data[0] == current_food_position:
		# DEBUGGING: Konfirmasi makanan dimakan
		print("!!! Food eaten at position: ", current_food_position)
		
		# Menggunakan get_node_or_null untuk menghindari error jika "Food" sudah tidak ada
		var food_node = get_node_or_null("Food")
		if is_instance_valid(food_node):
			score += food_node.score
			food_node.queue_free() # Menghilangkan makanan
		
		add_segment(old_data[-1])
		food_was_eaten = true # Memberi sinyal untuk spawn baru
		
		food_eaten_this_level += 1
		_update_hud()
		
		var level = level_data[current_level_index]
		if food_eaten_this_level >= level["goal"]:
			current_level_index += 1
			if current_level_index >= len(level_data):
				print("GAME TAMAT!")
				end_game() # Atau tampilkan layar kemenangan
			else:
				# Tampilkan layar "Level Selesai"
				next_level_screen.show_screen(level_data[current_level_index]["level"])
				get_tree().paused = true # Jeda game saat layar ini muncul

func _spawn_food():
	# DEBUGGING: Konfirmasi fungsi spawn terpanggil
	print(">>> Spawning new food...")

	var possible_positions = []
	for x in range(cells):
		for y in range(cells):
			var potential_pos = Vector2(x, y)
			# Ensure food doesn't spawn on snake or obstacles
			if not potential_pos in snake_data and not potential_pos in current_level_obstacles:
				possible_positions.append(potential_pos)

	if possible_positions.is_empty():
		print("No possible positions for food. Ending game.")
		end_game()
		return

	var food_types = food_data.keys()
	# Ensure food_types is not empty
	if food_types.is_empty():
		push_error("No food types defined in food_data!")
		end_game()
		return

	var random_food_name = food_types[randi() % food_types.size()]
	var selected_food_data = food_data[random_food_name]
	
	var new_food_pos = possible_positions[randi() % possible_positions.size()]
	self.current_food_position = new_food_pos
	
	var food_instance = FoodScene.instantiate()
	food_instance.name = "Food" # Penting untuk referensi $Food
	add_child(food_instance)
	
	food_instance.setup(random_food_name, selected_food_data["score"], selected_food_data["texture"], cell_size)
	food_instance.grid_position = new_food_pos
	food_instance.position = (new_food_pos * cell_size) # Adjust for cell_size if your textures are top-left anchored.
	
	print(">>> New food spawned at: ", new_food_pos)

func end_game():
	game_over_menu.show()
	move_timer.stop()
	get_tree().paused = true
s;dlvbslkjvbsldhv	
func _on_game_over_menu_restart():
	new_game()

func _on_next_level_screen_proceed_to_next_level():
	get_tree().paused = false # Lanjutkan game
	_start_level() # Mulai level berikutnya
