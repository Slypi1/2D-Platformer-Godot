extends Node

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 3

var current_health: int


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	if current_health <= 0 or amount <= 0:
		return

	current_health = maxi(0, current_health - amount)

	health_changed.emit(current_health, max_health)

	print("HP: ", current_health, "/", max_health)

	if current_health == 0:
		died.emit()
