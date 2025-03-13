extends CanvasLayer

@export var start_menu: String = "res://scenes/start_menu.tscn"
@onready var main_music = $MainMusic

@onready var mobile_controls = $MobileControls


var music_scene_instance: Node

func _ready():
	LivesUI.visible = true


func _set_main_music(play_music: bool) -> void:
	if main_music:
		if play_music:
			if not main_music.playing:
				main_music.play()
		else:
			if main_music.playing:
				main_music.stop()

func _toggle_mobile_controls():
	if mobile_controls.visible:
		mobile_controls.visible = false
	else:
		mobile_controls.visible = true

func _on_settings_button_pressed() -> void:
	GameManager._go_to_settings()
