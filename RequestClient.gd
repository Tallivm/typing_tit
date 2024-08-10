extends Node

@onready var spotify_client = $SpotifyClient
@onready var genius_client = $GeniusClient

const REDIRECT_URI: String = "http://localhost:8889/callback"
const LIKED_SONGS_URL = "https://api.spotify.com/v1/me/tracks"
const LYRICS_SEARCH_URL = "https://api.genius.com/search?q="
const LYRICS_GET_URL = "https://api.genius.com/songs/"


func get_random_string() -> String:
	var string: String = ""
	for i in range(16):
		string += str(randi() % 10)
	return string


func authorize_spotify_and_genius():
	spotify_client.authorization(REDIRECT_URI, get_random_string())
	genius_client.authorization(REDIRECT_URI, get_random_string())

func request_spotify_access_token(code):
	spotify_client.request_access_token(code, REDIRECT_URI)
	
func request_genius_access_token(code):
	genius_client.request_access_token(code, REDIRECT_URI)

func get_code_from_redirect_link(redirect: String) -> String:
	# TODO: compare the new state with original state
	var code = redirect.split(REDIRECT_URI + "?code=")[1].split("&state")[0]
	return code

func string_to_url(string: String) -> String:
	string = string.replace('%', '%25')
	
	string = string.replace(' ', '%20')
	string = string.replace('"', '%22')
	string = string.replace('#', '%23')	
	string = string.replace('&', '%26')
	string = string.replace('+', '%2b')
	string = string.replace(',', '%2c')
	string = string.replace('/', '%2f')
	string = string.replace(':', '%3a')
	string = string.replace(';', '%3b')
	string = string.replace('<', '%3c')
	string = string.replace('=', '%3d')
	string = string.replace('>', '%3e')
	string = string.replace('?', '%3f')
	string = string.replace('@', '%40')
	string = string.replace('[', '%5b')
	string = string.replace('\\', '%5c')
	string = string.replace(']', '%5d')
	string = string.replace('^', '%5e')
	string = string.replace('`', '%60')
	string = string.replace('{', '%7b')
	string = string.replace('|', '%7c')
	string = string.replace('}', '%7d')
	string = string.replace('~', '%7e')
	return string


func fetch_liked_songs() -> void:
	print('Fetching songs...')
	print('Spotify token: ', spotify_client.access_token)
	var headers = ["Authorization: Bearer " + spotify_client.access_token]
	$HTTPRequestSongs.request_completed.connect(_on_liked_songs_received)
	$HTTPRequestSongs.request(LIKED_SONGS_URL, headers, HTTPClient.METHOD_GET)

func _on_liked_songs_received(result, response_code, headers, body) -> void:
	if response_code == 200:
		var response_songs = JSON.parse_string(body.get_string_from_utf8())
		var liked_songs = response_songs.items
		print('Received songs: ', liked_songs.size())
		search_song_in_genius(liked_songs[0])
	else:
		print('Got bad response code: ' + str(response_code))
		print(JSON.parse_string(body.get_string_from_utf8()))

func search_song_in_genius(song: Dictionary) -> void:
	print('Searching for lyrics from Genius...')
	print('Genius token: ', genius_client.access_token)
	var search_term = song["track"]["artists"][0]["name"] + ' ' + song["track"]["name"]
	search_term = string_to_url(search_term)
	print('Will search for: ', search_term)
	var headers = [
		"Authorization: Bearer " + genius_client.access_token
	]
	$HTTPRequestLyrics.request_completed.connect(_on_songs_received)
	$HTTPRequestLyrics.request(LYRICS_SEARCH_URL + search_term, headers, HTTPClient.METHOD_GET)

func _on_songs_received(result, response_code, headers, body) -> void:
	if response_code == 200:
		var response_lyrics = JSON.parse_string(body.get_string_from_utf8())
		for hit in response_lyrics.response.hits:
			var song_code = str(hit.result.id)
			get_lyrics_by_song_code(song_code)
	else:
		print('Got bad response code: ' + str(response_code))
		print(JSON.parse_string(body.get_string_from_utf8()))

func get_lyrics_by_song_code(song_code: String):
	print('Fetching lyrics by song code...')
	print('Will search for code: ', song_code)
	var headers = [
		"Authorization: Bearer " + genius_client.access_token
	]
	$HTTPRequestLyricsGet.request_completed.connect(_on_lyrics_received.bind(song_code))
	$HTTPRequestLyricsGet.request(LYRICS_GET_URL + song_code, headers, HTTPClient.METHOD_GET)

func _on_lyrics_received(result, response_code, headers, body, song_code) -> void:
	if response_code == 200:
		var response_lyrics = JSON.parse_string(body.get_string_from_utf8())
		var lyrics_path = response_lyrics.response.song.path
		lyrics_path = lyrics_path.erase(0, 1)
		var youtube_link = get_youtube_link(response_lyrics)
		print('Found Youtube link: ', youtube_link)
		print('Lyrics path: ', lyrics_path)
		var exit_code = OS.execute("assets/fetch_lyrics.exe",  [
			"-i", lyrics_path, 
			"-t", genius_client.access_token, 
			"-o", "assets/lyrics/" + song_code + ".txt",
			"-n", 8])
		print('Lyricsgenius done with exit code: ', exit_code)
	else:
		print('Got bad response code: ' + str(response_code))
		print(JSON.parse_string(body.get_string_from_utf8()))

func get_youtube_link(response_lyrics) -> String:
	for media in response_lyrics.response.song.media:
		if media.provider == "youtube":
			return media.url
	return ""
