extends Node2D

const GAME_OVER_SCENE = preload("res://scenes/GameOver.tscn")

var enemies_killed: int = 0

@onready var health_label: Label = $HUD/HealthLabel
@onready var kills_label: Label = $HUD/KillsLabel


func _ready() -> void:
	enemies_killed = 0
	update_health(3, 3)
	update_kills()

	var player = find_child("Player", true, false)

	if player != null:
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)


func _on_player_health_changed(
	current_health: int,
	max_health: int
) -> void:
	update_health(current_health, max_health)


func _on_player_died() -> void:
	var game_over = GAME_OVER_SCENE.instantiate()
	add_child(game_over)


func update_health(current_health: int, max_health: int) -> void:
	health_label.text = "HP: %d / %d" % [
		current_health,
		max_health
	]


func add_kill() -> void:
	enemies_killed += 1
	update_kills()


func update_kills() -> void:
	kills_label.text = "Убито: %d" % enemies_killed
