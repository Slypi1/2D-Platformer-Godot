extends CharacterBody2D

enum State {
	PATROL,
	CHASE,
	ATTACK
}

const GRAVITY: float = 980.0
const PATROL_SPEED: float = 60.0
const CHASE_SPEED: float = 100.0

const DETECT_DISTANCE: float = 220.0
const ATTACK_RANGE: float = 42.0
const ATTACK_HEIGHT: float = 45.0
const ATTACK_COOLDOWN: float = 1.0
const ATTACK_DAMAGE: int = 1

const MAX_CHASE_HEIGHT_DIFFERENCE: float = 60.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var ground_ray: RayCast2D = $GroundAheadRay
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_component = $HealthComponent

var direction: int = 1
var state: State = State.PATROL
var player: CharacterBody2D = null
var attack_timer: float = 0.0
var dead: bool = false


func _ready() -> void:
	ground_ray.enabled = true
	sprite.modulate = Color.WHITE
	animation_player.stop()

	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(die)


func _physics_process(delta: float) -> void:
	if dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	attack_timer = maxf(0.0, attack_timer - delta)

	find_player()

	match state:
		State.PATROL:
			patrol()
		State.CHASE:
			chase()
		State.ATTACK:
			attack()

	sprite.flip_h = direction < 0

	move_and_slide()

	if is_on_wall() and state == State.PATROL:
		direction *= -1



func find_player() -> void:
	
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")

		if players.is_empty():
			state = State.PATROL
			return

		player = players[0] as CharacterBody2D

	
	if player.get("dead") == true:
		player = null
		state = State.PATROL
		return

	var dx: float = absf(
		player.global_position.x - global_position.x
	)
	var dy: float = absf(
		player.global_position.y - global_position.y
	)

	if (
		dx > DETECT_DISTANCE
		or dy > MAX_CHASE_HEIGHT_DIFFERENCE
	):
		state = State.PATROL
		return

	if dx <= ATTACK_RANGE and dy <= ATTACK_HEIGHT:
		state = State.ATTACK
	else:
		state = State.CHASE



func patrol() -> void:
	ground_ray.target_position = Vector2(
		direction * 14.0,
		20.0
	)
	ground_ray.force_raycast_update()

	if is_on_floor() and not ground_ray.is_colliding():
		direction *= -1

	velocity.x = direction * PATROL_SPEED


func chase() -> void:
	if not is_instance_valid(player):
		state = State.PATROL
		return

	var dx: float = player.global_position.x - global_position.x
	var dy: float = absf(
		player.global_position.y - global_position.y
	)

	if dy > MAX_CHASE_HEIGHT_DIFFERENCE:
		player = null
		state = State.PATROL
		return

	direction = 1 if dx > 0.0 else -1

	if absf(dx) <= ATTACK_RANGE and dy <= ATTACK_HEIGHT:
		velocity.x = 0.0
		state = State.ATTACK
	else:
		velocity.x = direction * CHASE_SPEED


func attack() -> void:
	velocity.x = 0.0

	if not is_instance_valid(player):
		state = State.PATROL
		return

	var dx: float = absf(
		player.global_position.x - global_position.x
	)
	var dy: float = absf(
		player.global_position.y - global_position.y
	)

	if dx > ATTACK_RANGE or dy > ATTACK_HEIGHT:
		state = State.CHASE
		return

	direction = 1 if (
		player.global_position.x > global_position.x
	) else -1

	if attack_timer <= 0.0:
		player.take_damage(ATTACK_DAMAGE)
		attack_timer = ATTACK_COOLDOWN


func take_damage(amount: int) -> void:
	if dead:
		return

	health_component.take_damage(amount)

	if dead:
		return

	if animation_player.has_animation("hurt_enemy"):
		animation_player.stop()
		animation_player.play("hurt_enemy")


func _on_health_changed(
	current_health: int,
	max_health: int
) -> void:
	print("Здоровье врага: ", current_health, "/", max_health)


func die() -> void:
	if dead:
		return

	dead = true
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	var main = get_tree().current_scene

	if main != null and main.has_method("add_kill"):
		main.add_kill()

	queue_free()
