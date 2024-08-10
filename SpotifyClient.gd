extends Node

@onready var spotify_load_songs_button = $"../../CanvasLayer/IntroScreen/CenterContainer/VBoxContainer/HBoxContainer/SpotifyLoadButton"

signal spotify_token_obtained

const AUTH_URL = "https://accounts.spotify.com/authorize"
const TOKEN_URL: String = "https://accounts.spotify.com/api/token"
const CLIENT_ID: String = "4f57b4e580e54442b0c332cc1c8184e0"
const CLIENT_SECRET: String = "3265abd8864c4e90b8d31e8e008003a0"
const SCOPE: String = "user-library-read user-read-private"

const BASE64: String = "NGY1N2I0ZTU4MGU1NDQ0MmIwYzMzMmNjMWM4MTg0ZTA6MzI2NWFiZDg4NjRjNGU5MGI4ZDMxZThlMDA4MDAzYTA="

var access_token: String = ""


func authorization(redirect_uri: String, state: String) -> void:
	var auth_link = "%s?client_id=%s&response_type=code&redirect_uri=%s&scope=%s&state=%s" % [AUTH_URL, CLIENT_ID, redirect_uri, SCOPE, state]
	OS.shell_open(auth_link)

func request_access_token(code: String, redirect_uri: String) -> void:
	#var auth_string = CLIENT_ID + ":" + CLIENT_SECRET
	#var base64_auth = auth_string.utf8_to_base64()
	#print(base64_auth)
	print("Requesting token")
	var headers = [
		"Authorization: Basic " + BASE64,
		"Content-Type: application/x-www-form-urlencoded"
		]
	var body = "code=%s&redirect_uri=%s&grant_type=authorization_code" % [code, redirect_uri]
	$HTTPRequestAuth.request_completed.connect(_on_token_received)
	$HTTPRequestAuth.request(TOKEN_URL, headers, HTTPClient.METHOD_POST, body)

func _on_token_received(result, response_code, headers, body):
	if response_code == 200:
		var json_result = JSON.parse_string(body.get_string_from_utf8())
		access_token = json_result.access_token
		spotify_token_obtained.emit()
	else:
		print('Got bad response code: ' + str(response_code))
		print(JSON.parse_string(body.get_string_from_utf8()))
