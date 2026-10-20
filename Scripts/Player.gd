extends CharacterBody2D

signal player_died
signal health_changed(current_health: int, max_health: int)

const SPEED: float = 200.0
const JUMP_VELOCITY: float = -350.0
const GRAVITY: float = 980.0

const SHOOT_COOLDOWN: float = 0.25
const DAMAGE_COOLDOWN: float = 0.7

const BULLET_SCENE = preload("res://scenes/bullet.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_component = $HealthComponent

var shoot_timer: float = 0.0
var damage_cooldown: float = 0.0
var dead: bool = false


func _ready() -> void:
	sprite.modulate = Color.WHITE
	animation_player.stop()

	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(die)

	health_changed.emit(
		health_component.current_health,
		health_component.max_health
	)


func _physics_process(delta: float) -> void:
	if dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if (
		(
			Input.is_key_pressed(KEY_W)
			or Input.is_action_just_pressed("ui_accept")
		)
		and is_on_floor()
	):
		velocity.y = JUMP_VELOCITY

	var direction: float = Input.get_axis("ui_left", "ui_right")

	if Input.is_key_pressed(KEY_A):
		direction = -1.0
	elif Input.is_key_pressed(KEY_D):
		direction = 1.0

	velocity.x = direction * SPEED

	if direction < 0.0:
		sprite.flip_h = true
	elif direction > 0.0:
		sprite.flip_h = false

	var facing: float = -1.0 if sprite.flip_h else 1.0
	muzzle.position.x = absf(muzzle.position.x) * facing

	shoot_timer = maxf(0.0, shoot_timer - delta)
	damage_cooldown = maxf(0.0, damage_cooldown - delta)

	if Input.is_key_pressed(KEY_J) and shoot_timer <= 0.0:
		shoot()
		shoot_timer = SHOOT_COOLDOWN

	move_and_slide()


func shoot() -> void:
	var bullet = BULLET_SCENE.instantiate()

	var facing: float = -1.0 if sprite.flip_h else 1.0
	bullet.direction = Vector2(facing, 0.0)
	bullet.shooter = self

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position


func take_damage(amount: int) -> void:
	if dead or damage_cooldown > 0.0:
		return

	health_component.take_damage(amount)
	damage_cooldown = DAMAGE_COOLDOWN

	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")


func _on_health_changed(
	current_health: int,
	max_health: int
) -> void:
	health_changed.emit(current_health, max_health)


func die() -> void:
	if dead:
		return

	dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	player_died.emit()

	print("Игрок погиб!")


func _unhandled_input(event: InputEvent) -> void:
	if dead and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_R:
			get_tree().reload_current_scene()
