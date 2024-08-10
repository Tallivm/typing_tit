extends Node2D

@onready var phrase_container = $CanvasLayer/GameScreen/PhraseContainer

@onready var song_name_value = $CanvasLayer/FinishedLyricsScreen/VBoxContainer/nameValue
@onready var artist_name_value = $CanvasLayer/FinishedLyricsScreen/VBoxContainer/artistValue

@onready var full_lyrics_container = $CanvasLayer/FinishedLyricsScreen/VBoxContainer/fullLyrics
@onready var link_button = $CanvasLayer/FinishedLyricsScreen/VBoxContainer/Link/LinkButton
@onready var dropdown_button = $CanvasLayer/IntroScreen/CenterContainer/VBoxContainer/LevelSelectionRow/LevelOptionButton

@onready var song_index_label = $CanvasLayer/ingameStats/HBoxContainer/SongIndexValue
@onready var char_count_label = $CanvasLayer/ingameStats/HBoxContainer/CharCountValue

@onready var accuracy_label = $CanvasLayer/FinishedLyricsScreen/VBoxContainer/HBoxContainer/accuracyLabel
@onready var speed_label = $CanvasLayer/FinishedLyricsScreen/VBoxContainer/HBoxContainer/speedLabel

@onready var enter_label = $CanvasLayer/GameScreen/VBoxContainer/enterLabel
@onready var next_song_button = $CanvasLayer/FinishedLyricsScreen/VBoxContainer/Next/NextSongButton

@onready var intro_screen = $CanvasLayer/IntroScreen
@onready var game_screen = $CanvasLayer/GameScreen
@onready var finished_lyrics_screen = $CanvasLayer/FinishedLyricsScreen
@onready var ingame_stats_screen = $CanvasLayer/ingameStats
@onready var request_screen = $CanvasLayer/RequestsSceen

@onready var request_client = $RequestClient
@onready var spotify_redirect_line = $CanvasLayer/RequestsSceen/VBoxContainer/spotifyRow/spotifyRowText
@onready var genius_redirect_line = $CanvasLayer/RequestsSceen/VBoxContainer/geniusRow/geniusRowText


var current_song_index: int = 0
var song_char_count: int = 0
var current_prompt_index: int = 0
var current_letter_index: int = 0
var wrong_letter_pos: Array = []
var current_prompt: String = ""

var is_game: bool = false
var lyrics_start_time: float = 0.0
var n_mistakes: float = 0.0

var requests_completed: int = 0


func switch_to_menu_screen() -> void:
	is_game = false
	game_screen.hide()
	request_screen.hide()
	ingame_stats_screen.hide()
	finished_lyrics_screen.hide()
	intro_screen.show()

func switch_to_game_screen() -> void:
	intro_screen.hide()
	request_screen.hide()
	finished_lyrics_screen.hide()
	game_screen.show()
	ingame_stats_screen.show()
	is_game = true

func switch_to_finish_lyrics_screen() -> void:
	is_game = false
	intro_screen.hide()
	request_screen.hide()
	game_screen.hide()
	ingame_stats_screen.show()
	if current_song_index + 1 == PromptList.phrases.size():
		next_song_button.hide()
	else:
		next_song_button.show()
	finished_lyrics_screen.show()

func switch_to_request_screen() -> void:
	is_game = false
	intro_screen.hide()
	game_screen.hide()
	ingame_stats_screen.hide()
	finished_lyrics_screen.hide()
	request_screen.show()


func _ready():
	add_dropdown_items()
	switch_to_menu_screen()


func add_dropdown_items() -> void:
	for i in PromptList.phrases.size():
		dropdown_button.add_item(str(i+1))


func _on_option_button_item_selected(index) -> void:
	current_song_index = index

func _on_start_button_pressed() -> void:
	switch_to_game_screen()
	start_song()

func _on_next_song_button_pressed() -> void:
	current_song_index += 1
	switch_to_game_screen()
	start_song()

func _on_menu_button_pressed():
	switch_to_menu_screen()


func update_char_counter() -> void:
	char_count_label.text = str(song_char_count)


func start_song() -> void:
	song_index_label.text = str(current_song_index + 1)
	phrase_container.load_song(current_song_index)
	current_prompt_index = 0
	n_mistakes = 0
	song_char_count = phrase_container.get_n_chars()
	update_char_counter()
	is_game = true
	start_prompt()

	artist_name_value.text = phrase_container.song_artist
	song_name_value.text = phrase_container.song_name
	link_button.uri = phrase_container.prompt_yt_link
	full_lyrics_container.text = phrase_container.get_full_lyrics()
	
	lyrics_start_time = Time.get_unix_time_from_system()

func start_prompt() -> void:
	enter_label.hide()
	current_letter_index = 0
	wrong_letter_pos = []
	phrase_container.load_prompt(current_prompt_index)
	current_prompt = phrase_container.prompts[current_prompt_index]
	

func add_letter(character_typed, next_character) -> void:
	if character_typed != next_character:
		add_wrong_letter(current_letter_index, character_typed)
	current_letter_index += 1
	song_char_count -= 1
	
	finalize_character_input()
	
func remove_letter() -> void:
	current_letter_index -= 1
	song_char_count += 1
		
	if (wrong_letter_pos.size() > 0) and (wrong_letter_pos[-1][0] == current_letter_index):
		remove_wrong_letter()
		
	finalize_character_input()

func finalize_character_input() -> void:
	phrase_container.color_current_prompt(current_prompt, current_letter_index, wrong_letter_pos)
	update_char_counter()
	toggle_enter_label()

func toggle_enter_label() -> void:
	if current_letter_index >= current_prompt.length():
		enter_label.show()
	else:
		enter_label.hide()

func add_wrong_letter(current_letter_index: int, character_typed) -> void:
	wrong_letter_pos.append([current_letter_index, character_typed])
	n_mistakes += 1.0

func remove_wrong_letter() -> void:
	wrong_letter_pos.remove_at(wrong_letter_pos.size() - 1)
	n_mistakes -= 0.5


func _unhandled_input(event: InputEvent) -> void:
	if (is_game) and (event is InputEventKey) and event.is_pressed():
		var character_typed = ""
		var next_character = current_prompt.substr(current_letter_index, 1)

		if event.unicode != 0:
			character_typed = char(event.unicode)
			print("Typed {%s}" % character_typed)
			
			add_letter(character_typed, next_character)

		elif (event.keycode == Key.KEY_BACKSPACE) and (current_letter_index > 0):
			remove_letter()

		elif event.keycode == Key.KEY_ENTER:

			# not last character
			if current_letter_index < current_prompt.length():
				pass  # TODO: should be considered a typing error

			# not last prompt
			elif current_prompt_index + 1 < phrase_container.prompts.size():
				current_prompt_index += 1
				start_prompt()

			else:
				show_lyrics_stats()


func show_lyrics_stats():
	var lyrics_time = Time.get_unix_time_from_system() - lyrics_start_time
	accuracy_label.text = str(calculate_accuracy()) + " %"
	speed_label.text = str(calculate_speed(lyrics_time)) + " char/s"
	switch_to_finish_lyrics_screen()


func calculate_accuracy() -> float:
	var n_chars = phrase_container.get_n_chars()
	return snappedf((n_chars - n_mistakes) / n_chars * 100, 0.01)

func calculate_speed(delta: float) -> float:
	return snappedf(phrase_container.get_n_chars() / delta, 0.001)


func _on_load_button_pressed():
	switch_to_request_screen()
	request_client.authorize_spotify_and_genius()

func _on_load_all_button_pressed():
	var spotify_redirect = spotify_redirect_line.text
	var genius_redirect = genius_redirect_line.text
	if spotify_redirect != "" and genius_redirect != "":
		var spotify_code = request_client.get_code_from_redirect_link(spotify_redirect)
		request_client.request_spotify_access_token(spotify_code)
		var genius_code = request_client.get_code_from_redirect_link(genius_redirect)
		request_client.request_genius_access_token(genius_code)

func _on_genius_client_genius_token_obtained():
	requests_completed += 1
	if requests_completed == 2:
		prepare_song_lyrics()

func _on_spotify_client_spotify_token_obtained():
	requests_completed += 1
	if requests_completed == 2:
		prepare_song_lyrics()

func prepare_song_lyrics():
	request_client.fetch_liked_songs()
