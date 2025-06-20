extends CanvasLayer

# Definisikan sebuah sinyal baru yang akan dikirim ke main.gd
signal proceed_to_next_level

# PASTIKAN PATH INI BENAR SESUAI DENGAN SCENE TREE ANDA
# Cara termudah: Seret node dari panel Scene ke sini.
@onready var title_label: Label = $Panel/TitleLabel
@onready var next_level_button: Button = $Panel/NextLevelButton

# Jika struktur Anda adalah CanvasLayer -> ColorRect -> Panel, gunakan path ini:
# @onready var title_label: Label = $ColorRect/Panel/TitleLabel
# @onready var next_level_button: Button = $ColorRect/Panel/NextLevelButton


func _ready():
	# Pemeriksaan untuk menghindari crash jika path salah
	if next_level_button:
		next_level_button.pressed.connect(_on_next_level_button_pressed)
	else:
		push_error("Node 'NextLevelButton' tidak ditemukan. Periksa path di nextlevel.gd!")
		
	if not title_label:
		push_error("Node 'TitleLabel' tidak ditemukan. Periksa path di nextlevel.gd!")

	hide() # Sembunyikan secara default

# Fungsi ini akan dipanggil dari main.gd
func show_screen(level_number: int):
	if title_label:
		title_label.text = "Level " + str(level_number) + " Selesai!"
	show()

# Saat tombol di dalam scene ini ditekan
func _on_next_level_button_pressed():
	hide() # Sembunyikan lagi layar ini
	# Kirim sinyal keluar untuk memberitahu main.gd agar melanjutkan game
	proceed_to_next_level.emit()
