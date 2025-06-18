# nextlevel.gd
extends CanvasLayer

# Definisikan sebuah sinyal baru yang akan dikirim ke main.gd
signal proceed_to_next_level

# Hubungkan node dari scene ke skrip dengan PATH YANG BENAR
@onready var title_label: Label = $ColorRect/Panel/TitleLabel
@onready var next_level_button: Button = $ColorRect/Panel/NextLevelButton

func _ready():
	# Hubungkan sinyal 'pressed' dari tombol ke fungsi di skrip ini
	next_level_button.pressed.connect(_on_next_level_button_pressed)
	hide() # Sembunyikan secara default

# Fungsi ini akan dipanggil dari main.gd
func show_screen(level_number: int):
	title_label.text = "Level " + str(level_number) + " Selesai!"
	show()

# Saat tombol di dalam scene ini ditekan
func _on_next_level_button_pressed():
	hide() # Sembunyikan lagi layar ini
	# Kirim sinyal keluar untuk memberitahu main.gd agar melanjutkan game
	proceed_to_next_level.emit()
