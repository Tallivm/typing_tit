extends Node2D

@export var typed_color = Color("#f2e9e4")
@export var current_color = Color("#d27c1f")
@export var wrong_color = Color("#c03432")
@export var left_color = Color("#9a8c98")

var prompts: Array = []
var song_artist: String = ""
var song_name: String = ""
var prompt_yt_link: String = ""

const END_COLOR_TAG = "[/color]"
const UNDERLINE_TAG = "[u]"
const END_UNDERLINE_TAG = "[/u]"

@onready var prompt_obj = $RichTextLabel


func load_song(song_index: int) -> void:
	var prompt_data = PromptList.phrases[song_index]
	prompts = prompt_data[0]
	song_artist = prompt_data[1]
	song_name = prompt_data[2]
	prompt_yt_link = prompt_data[3]
	load_prompt(0)
	

func load_prompt(prompt_index: int) -> void:
	var current_prompt = prompts[prompt_index]
	color_current_prompt(current_prompt, 0, [])


func color_current_prompt(prompt: String, next_char_index: int, wrong_letter_pos: Array) -> void:
	var typed_text = ""
	if wrong_letter_pos.size() > 0:
		# first color correctly typed start, if any
		typed_text = get_bbcode_color_tag(typed_color) + prompt.substr(0, wrong_letter_pos[0][0]) + END_COLOR_TAG
		# then color each single wrong character
		for i in range(wrong_letter_pos.size()):
			var pos = wrong_letter_pos[i][0]
			var wrong_letter = wrong_letter_pos[i][1]
			# one wrong character
			typed_text += get_bbcode_color_tag(wrong_color) + wrong_letter + END_COLOR_TAG
			# if this position is not the last in wrong character list:
			if wrong_letter_pos.size() > (i + 1):
				var next_pos = wrong_letter_pos[i + 1][0]
				typed_text += get_bbcode_color_tag(typed_color) + prompt.substr(pos + 1, next_pos - pos - 1) + END_COLOR_TAG
			else:
				typed_text += get_bbcode_color_tag(typed_color) + prompt.substr(pos + 1, next_char_index - pos - 1) + END_COLOR_TAG
	else:
		typed_text = get_bbcode_color_tag(typed_color) + prompt.substr(0, next_char_index) + END_COLOR_TAG

	var current_text = get_bbcode_color_tag(current_color) + prompt.substr(next_char_index, 1) + END_COLOR_TAG
	
	var left_text = ""
	if next_char_index != prompt.length():
		left_text = get_bbcode_color_tag(left_color) + prompt.substr(next_char_index + 1, -1) + END_COLOR_TAG

	prompt_obj.parse_bbcode(centered(UNDERLINE_TAG + typed_text + END_UNDERLINE_TAG + current_text + left_text))


func get_full_lyrics() -> String:
	return "\n".join(prompts)
	
func get_n_chars() -> int:
	var n_chars: int = 0
	for prompt in prompts:
		n_chars += prompt.length()
	return n_chars


func centered(to_center: String) -> String:
	return "[center]" + to_center + "[/center]"


func create_url(url: String) -> String:
	return '[url="' + url + '"]YouTube link[/url]'


func get_bbcode_color_tag(color: Color) -> String:
	return "[color=#" + color.to_html(false) + "]"
