# File: nextlevel.gd
extends CanvasLayer

# Sinyal ini akan memberitahu main.gd untuk melanjutkan ke level berikutnya
signal proceed_to_next_level

# Gunakan path yang unik untuk memastikan tidak salah node
@onready var title_label: Label = $TitleLabel
@onready var next_level_button: Button = $NextLevelButton

func _ready():
	# Koneksi sinyal dibuat di sini. 
	# PASTIKAN TIDAK ADA KONEKSI LAIN DARI EDITOR untuk menghindari error "already connected".
	hide() # Sembunyikan layar ini saat game dimulai

# Fungsi ini dipanggil oleh main.gd untuk menampilkan layar ini
func show_screen(level_number: int):
	title_label.text = "Level " + str(level_number) + " Selesai!"
	show()
	# Saat layar ini muncul, tombol harus bisa diklik
	next_level_button.disabled = false


# Saat tombol di scene ini ditekan
func _on_next_level_button_pressed():
	hide() # Sembunyikan layar ini lagi
	next_level_button.disabled = true # Matikan tombol untuk mencegah klik ganda
	# Kirim sinyal ke main.gd
	proceed_to_next_level.emit()
