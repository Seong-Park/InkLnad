class_name EnemyController
extends CharacterBody2D

signal defeated(spawn_id: StringName)
signal projectile_requested(origin: Vector2, direction: Vector2)
var rules: Resource
var spawn_id: StringName
var enemy_id: StringName
var hp: float = 24.0
var alive: bool = true
var stats: Dictionary
var player: PlayerController
var area: Node2D
var active: bool = true
var protection: float = 0.75
var phase: StringName = &"approach"
var timer: float = 0.0
var aim: Vector2 = Vector2.RIGHT
var contact_clock: float = 0.0
var dash_hit: bool = false
var navigation_clock: float = 0.0
var waypoint: Vector2
var walk_time: float = 0.0
var spawn_position: Vector2
@onready var portrait: Sprite2D = $Portrait
var portrait_rest_position: Vector2 = Vector2.ZERO
var portrait_base_scale: Vector2 = Vector2.ONE

func configure(id_value: StringName, type_value: StringName, hp_value: float) -> void:
	spawn_id = id_value
	enemy_id = type_value
	stats = rules.get_enemy(enemy_id)
	hp = hp_value
	alive = hp > 0.0
	spawn_position = position
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = float(stats.radius)
	$CollisionShape2D.shape = circle
	portrait.texture = preload("res://scripts/areas/watercolor_art.gd").texture(String(enemy_id))
	var painted: Rect2i = portrait.texture.get_image().get_used_rect()
	var display: Vector2 = {&"drop":Vector2(55,40), &"dash":Vector2(90,36), &"blot":Vector2(65,45), &"elite_dash":Vector2(140,55)}.get(enemy_id,Vector2.ONE * float(stats.radius) * 3.0)
	portrait_base_scale = Vector2(display.x / maxf(float(painted.size.x),1.0), display.y / maxf(float(painted.size.y),1.0))
	portrait.scale = portrait_base_scale
	portrait_rest_position = Vector2(
		-(float(painted.position.x) + float(painted.size.x) * 0.5 - portrait.texture.get_width() * 0.5) * portrait_base_scale.x,
		-(float(painted.end.y) - portrait.texture.get_height() * 0.5) * portrait_base_scale.y)
	portrait.position = portrait_rest_position
	timer = float(stats.shot_interval)-float(stats.telegraph) if enemy_id == &"blot" else 0.0
	visible = alive

func _physics_process(dt: float) -> void:
	contact_clock = maxf(0.0,contact_clock-dt)
	protection = maxf(0.0,protection-dt)
	if not alive or not active or player == null or protection > 0.0:
		velocity = Vector2.ZERO
		return
	timer -= dt
	var distance: float = position.distance_to(player.position)
	if enemy_id == &"drop":
		velocity = _approach(dt)*float(stats.speed)
	elif enemy_id == &"blot":
		velocity = Vector2.ZERO
		if phase == &"telegraph" and timer <= 0.0:
			projectile_requested.emit(position,aim)
			phase = &"approach"
			timer = float(stats.shot_interval)-float(stats.telegraph)
		elif phase == &"approach" and timer <= 0.0 and distance <= float(stats.detection_range):
			aim = position.direction_to(player.position)
			phase = &"telegraph"
			timer = float(stats.telegraph)
	else:
		var elite: bool = enemy_id == &"elite_dash"
		if phase == &"approach":
			velocity = _approach(dt)*float(stats.speed)
			if distance <= float(stats.detection_range):
				phase = &"telegraph"
				timer = float(stats.telegraph)
				aim = position.direction_to(player.position)
		elif phase == &"telegraph":
			velocity = Vector2.ZERO
			if timer <= 0.0:
				phase = &"dash"
				timer = float(stats.dash_duration)
				dash_hit = false
		elif phase == &"dash":
			velocity = aim*float(stats.dash_speed)
			if timer <= 0.0:
				_recover(elite)
		else:
			velocity = Vector2.ZERO
			if timer <= 0.0:
				phase = &"approach"
	if phase == &"approach" and velocity.length() > 0.0:
		for other in area.enemies:
			if other != self and other.alive:
				var difference: Vector2 = position-other.position
				if difference.length() < float(stats.radius)+float(other.stats.radius)+5.0 and difference.length()>0.1:
					velocity += difference.normalized()*20.0
	move_and_slide()
	if phase == &"dash" and get_slide_collision_count()>0:
		_recover(enemy_id == &"elite_dash")
	walk_time += dt
	portrait.scale = portrait_base_scale * (Vector2(1.3,0.8) if phase == &"dash" else (Vector2(0.92,1.08) if phase == &"telegraph" else Vector2.ONE))
	portrait.position = portrait_rest_position + Vector2(0.0, sin(walk_time * 8.0) * 1.5 if velocity.length()>1 else 0.0)
	portrait.rotation = sin(walk_time*8.0)*0.05 if velocity.length()>1 else 0.0
	queue_redraw()

func _recover(_elite: bool) -> void:
	phase = &"recover"
	timer = float(stats.recovery)
	velocity = Vector2.ZERO

func _approach(dt: float) -> Vector2:
	if area.exploration_navigation == null and area.area_id != &"D":
		return position.direction_to(player.position)
	navigation_clock -= dt
	if navigation_clock <= 0.0 or waypoint.distance_to(position)<10.0:
		waypoint = area.next_waypoint(position,player.position,float(stats.radius))
		navigation_clock = 0.25
	return position.direction_to(waypoint)

func incoming_hit() -> float:
	if not alive or not active or protection > 0.0 or position.distance_to(player.position)>float(stats.radius)+12.0:
		return 0.0
	if phase == &"dash":
		if dash_hit:
			return 0.0
		dash_hit = true
		return float(stats.dash_damage)
	if contact_clock > 0.0:
		return 0.0
	contact_clock = float(stats.contact_interval)
	return float(stats.contact_damage)

func receive_damage(amount: float) -> void:
	if not alive or protection > 0.0:
		return
	hp = maxf(0.0,hp-amount)
	if hp <= 0.0:
		alive = false
		visible = false
		velocity = Vector2.ZERO
		defeated.emit(spawn_id)
	queue_redraw()

func capture() -> Dictionary:
	return {"spawn_id":String(spawn_id),"enemy_id":String(enemy_id),"hp":hp,"alive":alive}

func _draw() -> void:
	if stats.is_empty() or not alive:
		return
	draw_circle(Vector2.ZERO,float(stats.radius),Color(0.23,0.2,0.18,0.12))
	if phase == &"telegraph":
		draw_arc(Vector2.ZERO,float(stats.radius)+7.0,0,TAU,32,Color("8D3154"),2.0,true)
		draw_dashed_line(Vector2.ZERO,aim*130,Color("8D3154"),2.0,8.0,true)
	var fraction: float = hp/float(stats.hp)
	if fraction < 1.0:
		draw_line(Vector2(-20,-50),Vector2(20,-50),Color(0.23,0.2,0.18,0.25),3.0)
		draw_line(Vector2(-20,-50),Vector2(-20+40*fraction,-50),Color("1749C6"),3.0)
