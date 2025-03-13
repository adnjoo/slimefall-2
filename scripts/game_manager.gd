extends Node

@export var start_menu: String = "res://scenes/start_menu.tscn"
@export var SAVE_PATH = "user://high_scores.cfg"
@export var score: int = 0
@export var high_score = 0

@export var collected_coins = {}  # Dictionary to track collected coins

func collect_coin(coin_id: String):
	collected_coins[coin_id] = true  # Mark coin as collected

func is_coin_collected(coin_id: String) -> bool:
	return collected_coins.get(coin_id, false)  # Return if the coin was collected

func _ready():
	GameManager.load_high_score()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_go_to_settings()

func _go_to_settings():
	get_tree().change_scene_to_file(start_menu)
	LivesUI.mobile_controls.visible = false

func load_high_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		high_score = int(file.get_line())  # Read saved high score
		file.close()

# Save the new high score if it's higher
func save_high_score(current_score: int):
	if current_score > high_score:
		high_score = current_score  # Update high score
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		file.store_line(str(high_score))  # Save the high score
		file.close()

func handle_game_end(is_win: bool):
	"""
	Handles the game-over or game-win logic.

	Args:
		is_win (bool): If true, handles the win scenario; otherwise, handles game over.
	"""
	LivesUI._set_main_music(false)  # Stop music
	
	if is_win:
		LivesUI.game_win.play()
		GameManager.save_high_score(GameManager.score)
		LivesUI.win_label2.text = "Your score is: " + str(GameManager.score)
		LivesUI.vbox_container.visible = true
		await get_tree().create_timer(3).timeout  # Wait before switching scene
	else:
		LivesUI.sad_sound.play()
		LivesUI.visible = false

	collected_coins = {}  # Reset collected coins
	LivesUI.reset_points()  # Reset points

	get_tree().change_scene_to_file(start_menu)
	
	await get_tree().create_timer(1).timeout
	LivesUI._set_main_music(true)
