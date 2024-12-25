extends Control

@export var ServerAddr = "localhost"
@export var ServerPort = 67

@export var ClientAddr = "Swipez-59818.portmap.host"
@export var ClientPort = 59818
var peer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(peerConnected)
	multiplayer.peer_disconnected.connect(peerDisconnected)
	multiplayer.connected_to_server.connect(connectedToServer)
	multiplayer.connection_failed.connect(connectionFailed)
	if "--server" in OS.get_cmdline_args():
		hostGame()

# From client and server
func peerConnected(id):
	print("Player Connected : ", id)
func peerDisconnected(id):
	print("Player Disconnected : ", id)
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
# Only from client
func connectedToServer():
	print("Connected to Server!")
	sendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())
func connectionFailed():
	print("Connection Failed!")

@rpc("any_peer")
func sendPlayerInformation(nama, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": nama,
			"id": id,
		}
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			sendPlayerInformation.rpc(GameManager.Players[i].name, i)

@rpc("any_peer", "call_local")
func startGame():
	var scene = load("res://scene/testScene.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func hostGame():
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(ServerPort, 2)
	if err != OK:
		print("Cannot host: " + str(err))
		return
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for player!")

func _on_host_button_down() -> void:
	hostGame()
	sendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())
	pass # Replace with function body.

func _on_join_button_down() -> void:
	print("Attempting to connect to:", ClientAddr, ":", ClientPort)
	peer = ENetMultiplayerPeer.new()
	if peer.create_client(ClientAddr, ClientPort) != OK:
		print("Failed to connect to server at:", ClientAddr, ":", ClientPort)
	else:
		print("Connected to server at:", ClientAddr, ":", ClientPort)
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	pass # Replace with function body.


func _on_start_game_button_down() -> void:
	startGame.rpc()
	pass # Replace with function body.
