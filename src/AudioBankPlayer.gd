class_name AudioBankPlayer

extends AudioStreamPlayer

@export var sounds: Array[AudioStream]


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(len(sounds)):
		sounds[i] = sounds[i]


#		sounds[i].set_loop(false)


func play_sound():
	if sounds.size() == 0:
		print(name, " PLACEHOLDER SOUND")
		return

	stream = sounds[randi() % len(sounds)]
	super.play()
