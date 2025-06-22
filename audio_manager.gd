# File: audio_manager.gd
extends Node

# Siapkan referensi ke node pemutar musik kita
@onready var music_player = $MusicPlayer
@onready var sfx_player = $SfxPlayer

# Fungsi untuk memulai musik latar
func play_music():
	# Hanya putar jika musiknya belum berputar
	if not music_player.is_playing():
		music_player.play()

# Fungsi untuk menghentikan musik latar
func stop_music():
	music_player.stop()

func play_sfx(sfx_stream: AudioStream):
	# Pastikan kita diberi file suara yang valid
	if sfx_stream:
		# Masukkan file suara ke dalam SfxPlayer
		sfx_player.stream = sfx_stream
		# Putar suaranya sekali
		sfx_player.play()
# (Di masa depan, Anda bisa tambahkan fungsi untuk efek suara di sini)
# func play_sfx(sound_path):
#	  ...
