extends AudioStreamPlayer

func _ready() -> void:
	if not playing:
		play()
	finished.connect(play)
