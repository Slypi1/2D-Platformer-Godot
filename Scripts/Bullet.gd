extends Area2D

const SPEED: float = 500.0
const DAMAGE: int = 1

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta


func _draw() -> void:
	draw_rect(
		Rect2(Vector2(-5, -2), Vector2(10, 4)),
		Color.YELLOW
	)


func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(shooter) and body == shooter:
		return

	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)

	queue_free()
