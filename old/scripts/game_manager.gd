extends Node

@export var start_menu: String = "res://scenes/start_menu.tscn"

func _ready():
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_go_to_settings()

func _go_to_settings():
	get_tree().change_scene_to_file(start_menu)
	LivesUI.mobile_controls.visible = false
