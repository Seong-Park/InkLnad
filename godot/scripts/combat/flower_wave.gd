extends Node2D

const RADIUS: float = 180.0
const COST: float = 20.0
const COOLDOWN: float = 5.0
const WINDUP: float = 0.3
const SPREAD: float = 0.6
const DAMAGE: float = 24.0
var cooldown: float = 0.0
var age: float = -1.0
var center: Vector2 = Vector2.ZERO
var hit_targets: Dictionary = {}
var flowers: Texture2D = preload("res://assets/world/flowers.png")
var flower_region: Rect2

func _ready() -> void:
	z_index = 2
	flower_region = Rect2(flowers.get_image().get_used_rect())

func begin(origin: Vector2) -> void:
	center = origin
	age = 0.0
	cooldown = COOLDOWN
	hit_targets.clear()
	queue_redraw()

func cancel() -> void:
	age = -1.0
	hit_targets.clear()
	queue_redraw()

func reset() -> void:
	cancel()
	cooldown = 0.0

func tick(dt: float) -> void:
	cooldown = maxf(0.0,cooldown-dt)
	if age >= 0.0:
		age += dt
		if age > WINDUP+SPREAD+0.7:
			cancel()
		queue_redraw()

func damage_for(target: Object, point: Vector2, target_radius: float) -> float:
	if age < WINDUP or age > WINDUP+SPREAD+0.1 or hit_targets.has(target.get_instance_id()):
		return 0.0
	var wave_radius: float = RADIUS*clampf((age-WINDUP)/SPREAD,0.0,1.0)
	if center.distance_to(point) > wave_radius+target_radius:
		return 0.0
	var ray := PhysicsRayQueryParameters2D.create(center,point,1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return 0.0
	hit_targets[target.get_instance_id()] = true
	return DAMAGE

func _draw() -> void:
	if age < 0.0:
		return
	var progress: float = clampf((age-WINDUP)/SPREAD,0.0,1.0)
	var fade: float = 1.0-clampf((age-WINDUP-SPREAD)/0.7,0.0,1.0)
	var radius: float = 12.0+RADIUS*progress
	# Thin translucent washes retain the paper underneath, with uneven edges.
	for layer in range(4):
		draw_arc(center+Vector2(sin(layer*2.1),cos(layer*1.7))*2.5,radius-layer*3.0,0,TAU,80,Color(0.66,0.72,0.57,0.10*fade),5.0,true)
	for index in range(24):
		var ring: float = 0.35+0.65*float(index%3)/2.0
		var bloom_time: float = float(index%3)*0.19
		var bloom: float = clampf((age-WINDUP-bloom_time)/0.22,0.0,1.0)
		if bloom <= 0.0:
			continue
		var angle: float = index*2.399963
		var point: Vector2 = center+Vector2.from_angle(angle)*RADIUS*ring
		var height: float = (26.0+float(index%4)*4.0)*bloom
		var extent: Vector2 = flower_region.size*(height/maxf(1.0,flower_region.size.y))
		draw_texture_rect_region(flowers,Rect2(point-extent*Vector2(0.5,0.85),extent),flower_region,Color(1.0,0.94,0.98,0.85*fade))
		for petal in range(3):
			var drift: Vector2 = Vector2.from_angle(angle+petal*1.8)*(8.0+age*9.0)
			draw_circle(point+drift+Vector2(0,-age*8.0),2.0,Color(0.86,0.58,0.65,0.32*fade*bloom))
