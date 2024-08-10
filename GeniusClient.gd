extends Node

signal genius_token_obtained

const AUTH_URL = "https://api.genius.com/oauth/authorize"
const TOKEN_URL = "https://api.genius.com/oauth/token"
const CLIENT_ID = "Wh74Cz6JQMfrd57fgopxUogBfbr6PLacQxd2U6VQomOatLMeCON6POXBgVNjJTNQ"
const CLIENT_SECRET = "--RvjcQ5fkekGw7mCqdFx3nj2F_MTdzoeevs2EF4homMxGjzfDZAFef2v2-efqIKEII4257N8OzKbGK85Pcb4g"
const SCOPE = ""

var access_token = ""


func authorization(redirect_uri: String, state: String) -> void:
	var auth_link = "%s?client_id=%s&response_type=code&redirect_uri=%s&scope=%s&state=%s" % [AUTH_URL, CLIENT_ID, redirect_uri, SCOPE, state]
	OS.shell_open(auth_link)

func request_access_token(code: String, redirect_uri: String) -> void:
	print("Requesting token")
	var headers = []
	var body = "code=%s&redirect_uri=%s&grant_type=authorization_code&client_id=%s&client_secret=%s&response_type=code" % [code, redirect_uri, CLIENT_ID, CLIENT_SECRET]
	$HTTPRequestAuth.request_completed.connect(_on_token_received)
	$HTTPRequestAuth.request(TOKEN_URL, headers, HTTPClient.METHOD_POST, body)

func _on_token_received(result, response_code, headers, body):
	if response_code == 200:
		var json_result = JSON.parse_string(body.get_string_from_utf8())
		access_token = json_result.access_token
		genius_token_obtained.emit()
	else:
		print('Got bad response code: ' + str(response_code))
		print(JSON.parse_string(body.get_string_from_utf8()))
