extends Node2D

@export var multiplayer_game: String = "res://levels/multiplayer_game.tscn"
@export var lives_ui = "res://scenes/lives_ui.tscn"

@onready var start_button = $StartMenuContainer/StartButton  # Adjusted path to the StartButton
@onready var settings_button = $StartMenuContainer/SettingsButton  # Adjusted path to the StartButton
@onready var start_menu_panel = $StartMenuContainer
@onready var about_link = $AboutLink  # Adjusted path to the StartButton
@onready var settings_menu = $SettingsMenu

@onready var hi_score_label = $HiScoreLabel

func _ready():
	LivesUI.visible = false
	
func toggle_settings_menu():
	settings_menu.visible = not settings_menu.visible
	get_tree().paused = settings_menu.visible  # Pause game when settings is open

# Separate the game start logic into a new function
func start_game():
	LivesUI.visible = true
	LivesUI.mobile_controls.visible = true
	
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(multiplayer_game)

# Start Button Pressed Logic
func _on_start_button_pressed():
	start_game()

# Settings
func _on_settings_button_pressed() -> void:
	start_menu_panel.hide()
	settings_menu.show()

func _on_settings_back_button_pressed() -> void:
	settings_menu.hide()
	start_menu_panel.show()

func _on_mute_back_button_pressed() -> void:
	if LivesUI.main_music.playing:
		LivesUI._set_main_music(false)
	else:
		LivesUI._set_main_music(true)

func _on_hi_scores_button_pressed() -> void:
	print(GameManager.high_score)
