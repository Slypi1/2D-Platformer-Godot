extends CanvasLayer

@onready var message: Label = $Background/Message


func _ready() -> void:
	message.text = "GAME OVER\nНажми R для перезапуска"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_R:
			get_tree().reload_current_scene()
