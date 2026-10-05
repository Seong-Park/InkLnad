extends Node2D

const DATA: Dictionary = {
	"paint": {"cost":12.0,"cooldown":2.0,"color":Color("729bcf")},
	"flower": {"cost":20.0,"cooldown":5.0,"color":Color("d69caf")},
	"spring": {"cost":30.0,"cooldown":8.0,"color":Color("79bdb3")}
}
var cooldowns: Dictionary = {"paint":0.0,"flower":0.0,"spring":0.0}
var player: PlayerController
var wave = preload("res://scripts/combat/flower_wave.gd").new()
var bullet: Dictionary = {}
var spring: Dictionary = {}
var auras: Array[Dictionary] = []
var impacts: Array[Dictionary] = []

func _ready() -> void:
	z_index = 3
	add_child(wave)

func begin(id: String, origin: Vector2, target: Vector2) -> void:
	cooldowns[id] = DATA[id].cooldown
	auras.append({"id":id,"age":0.0})
	match id:
		"flower": wave.begin(origin)
		"paint": bullet = {"position":origin,"direction":origin.direction_to(target),"age":0.0}
		"spring": spring = {"position":origin+(target-origin).limit_length(180.0),"age":0.0,"hits":{}}
	queue_redraw()

func cancel() -> void:
	wave.cancel()
	bullet.clear()
	spring.clear()
	auras.clear()
	impacts.clear()
	queue_redraw()

func reset() -> void:
	cancel()
	for id in cooldowns:
		cooldowns[id] = 0.0

func _visible_target(origin: Vector2, target: Vector2) -> bool:
	return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(origin,target,1)).is_empty()

func _hit(enemy: EnemyController, amount: float, id: String) -> void:
	if not enemy.alive or enemy.protection > 0.0:
		return
	enemy.receive_damage(amount)
	impacts.append({"id":id,"target":weakref(enemy),"position":enemy.global_position,"age":0.0})

func tick(dt: float, enemies: Array[EnemyController]) -> void:
	for id in cooldowns:
		cooldowns[id] = maxf(0.0,float(cooldowns[id])-dt)
	for effects in [auras,impacts]:
		for index in range(effects.size()-1,-1,-1):
			effects[index].age += dt
			if effects[index].age > 0.8:
				effects.remove_at(index)
	wave.tick(dt)
	for enemy in enemies:
		if enemy.alive and enemy.protection <= 0.0:
			var damage: float = wave.damage_for(enemy,enemy.global_position,float(enemy.stats.radius))
			if damage > 0.0:
				_hit(enemy,damage,"flower")
				if get_tree().paused:
					return
	if not bullet.is_empty():
		var previous_age: float = bullet.age
		bullet.age += dt
		var travel_dt: float = maxf(0.0,float(bullet.age)-0.3)-maxf(0.0,previous_age-0.3)
		var start: Vector2 = bullet.position
		var end: Vector2 = start+bullet.direction*420.0*travel_dt
		var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(start,end,1)) if travel_dt > 0.0 else {}
		if not wall.is_empty():
			end = wall.position
		var nearest: EnemyController = null
		var distance: float = INF
		if travel_dt > 0.0:
			for enemy in enemies:
				if not enemy.alive or enemy.protection > 0.0:
					continue
				var hit: float = Geometry2D.segment_intersects_circle(start,end,enemy.global_position,float(enemy.stats.radius)+7.0)
				if hit >= 0.0 and hit < distance and _visible_target(start,enemy.global_position):
					distance = hit
					nearest = enemy
		bullet.position = end
		if nearest != null:
			_hit(nearest,28.0,"paint")
		if nearest != null or not wall.is_empty() or bullet.age > 2.0:
			bullet.clear()
	if not spring.is_empty() and not get_tree().paused:
		spring.age += dt
		var pulse: int = int(floor((float(spring.age)-0.3)/1.0))
		if pulse >= 0 and pulse < 3:
			for enemy in enemies:
				var key: int = enemy.get_instance_id()
				if enemy.alive and enemy.protection <= 0.0 and int(spring.hits.get(key,-1)) < pulse and enemy.global_position.distance_to(spring.position) <= 100.0+float(enemy.stats.radius) and _visible_target(spring.position,enemy.global_position) and _visible_target(player.global_position,spring.position):
					spring.hits[key] = pulse
					_hit(enemy,10.0,"spring")
					if get_tree().paused:
						return
		if spring.age > 3.6:
			spring.clear()
	queue_redraw()

func _wash(point: Vector2, radius: float, color: Color, alpha: float) -> void:
	for layer in range(4):
		var tint: Color = color
		tint.a = alpha*0.12
		draw_circle(point+Vector2(sin(layer*2.3),cos(layer*1.9))*2.0,radius-layer*2.0,tint)

func _draw() -> void:
	if player == null:
		return
	for aura in auras:
		var color: Color = DATA[aura.id].color
		var fade: float = 1.0-float(aura.age)/0.8
		var foot: Vector2 = player.global_position
		_wash(foot,24.0+float(aura.age)*12.0,color,fade)
		for index in range(8):
			var angle: float = index*TAU/8.0+float(aura.age)*2.0
			var point: Vector2 = foot+Vector2(cos(angle)*34.0,sin(angle)*18.0-45.0-float(aura.age)*40.0)
			color.a = fade*0.9
			match aura.id:
				"flower": draw_circle(point,3.5,color)
				"paint": draw_line(point,point+Vector2(5,-12),color,3.0,true)
				"spring": draw_arc(foot+Vector2(0,-index*9.0),24.0+index,0,TAU,32,Color(color,fade*0.23),1.5,true)
	if not bullet.is_empty() and bullet.age >= 0.3:
		var color: Color = DATA.paint.color
		_wash(bullet.position,10.0,color,1.0)
		for index in range(5):
			color.a = 0.4*(1.0-index/5.0)
			draw_circle(bullet.position-bullet.direction*index*8.0,6.0-index*0.8,color)
	if not spring.is_empty():
		var alpha: float = minf(clampf((float(spring.age)-0.3)*3.0,0.0,1.0),clampf((3.6-float(spring.age))/0.5,0.0,1.0))
		_wash(spring.position,100.0,DATA.spring.color,alpha)
		for index in range(4):
			var radius: float = fmod(float(spring.age)*48.0+index*25.0,100.0)
			draw_arc(spring.position,radius,0,TAU,64,Color(0.37,0.66,0.65,alpha*(1.0-radius/100.0)*0.35),2.5,true)
	for impact in impacts:
		var enemy: Object = impact.target.get_ref()
		var point: Vector2 = enemy.global_position if is_instance_valid(enemy) else impact.position
		point += Vector2(0,-28)
		var color: Color = DATA[impact.id].color
		color = color.lightened(0.25)
		var fade: float = 1.0-float(impact.age)/0.8
		_wash(point,12.0+float(impact.age)*22.0,color,fade)
		for index in range(7):
			var offset: Vector2 = Vector2.from_angle(index*TAU/7.0)*(8.0+float(impact.age)*32.0)
			color.a = fade*0.65
			if impact.id == "paint":
				draw_line(point+offset,point+offset*1.4,color,3.0,true)
			elif impact.id == "flower":
				draw_circle(point+offset,4.0,color)
			else:
				draw_arc(point,offset.length(),0,TAU,32,Color(color,fade*0.15),1.5,true)
