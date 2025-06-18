# food.gd
extends Area2D

# Variabel untuk menyimpan data makanan
var type: String
var score: int
var grid_position: Vector2

@onready var sprite: Sprite2D = $Sprite2D

# REVISI: Tambahkan 'target_size' sebagai parameter
func setup(food_type: String, food_score: int, food_texture: Texture, target_size: float):
	self.type = food_type
	self.score = food_score
	self.sprite.texture = food_texture
	
	# --- BAGIAN BARU: MENGHITUNG SKALA OTOMATIS ---
	# 1. Dapatkan ukuran asli dari gambar (misal: 256x256 pixel)
	var texture_size = self.sprite.texture.get_size()
	
	# 2. Cari sisi terpanjang dari gambar
	var max_dimension = max(texture_size.x, texture_size.y)
	
	# 3. Hitung skala yang dibutuhkan agar sisi terpanjang itu pas dengan ukuran kotak
	var scale_factor = target_size / max_dimension
	
	# 4. Terapkan skala baru ke sprite
	self.sprite.scale = Vector2(scale_factor, scale_factor)
