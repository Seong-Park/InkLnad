class_name AreaRuntime
extends Node2D

signal exit_requested(exit_id: StringName)
var rules: Resource
var area_id: StringName = &"A"
var area_size: Vector2 = Vector2(1120,560)
var enemies: Array[EnemyController] = []
var projectiles: Array[Dictionary] = []
var player: PlayerController
var restored: bool = false
var left_open: bool = true
var right_open: bool = true
var enemy_scene: PackedScene = preload("res://scenes/enemies/Enemy.tscn")
var npc_texture: Texture2D = preload("res://scripts/areas/watercolor_art.gd").texture("npc")
var obstacle: Rect2 = Rect2(700,180,60,100)
var bodies: Array[StaticBody2D] = []
var font: SystemFont = SystemFont.new()
var flower_texture: Texture2D = preload("res://assets/world/flowers.png")
var doorway_texture: Texture2D = preload("res://assets/world/doorway.png")
var workshop_texture: Texture2D = preload("res://assets/world/workshop.png")
var target_texture: Texture2D = preload("res://scripts/areas/watercolor_art.gd").texture("target")
var checkpoint_texture: Texture2D = preload("res://assets/world/checkpoint.png")
var pillar_texture: Texture2D = preload("res://assets/world/ruin-pillar.png")
var paper_texture: Texture2D = preload("res://assets/world/paper-arena.png")
var ruins_texture: Texture2D = preload("res://assets/world/bluebell-ruins.png")
var rain_texture: Texture2D = preload("res://assets/world/rain-margin.png")
var _regions: Dictionary = {}
var coastal_map: Node2D
var exploration_navigation: AStarGrid2D
var _building_sprite: Sprite2D
var _unrestored_material: ShaderMaterial

func _ready() -> void:
	y_sort_enabled = true
	_building_sprite = Sprite2D.new()
	_building_sprite.texture = workshop_texture
	_building_sprite.region_enabled = true
	_building_sprite.region_rect = _region(workshop_texture)
	_building_sprite.z_index = -1
	add_child(_building_sprite)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float g=dot(c.rgb,vec3(0.299,0.587,0.114)); COLOR=vec4(mix(vec3(0.95,0.91,0.82),vec3(g),0.55),c.a*0.65); }"
	_unrestored_material = ShaderMaterial.new()
	_unrestored_material.shader = shader

func _region(texture: Texture2D) -> Rect2:
	if not _regions.has(texture):
		_regions[texture] = Rect2(texture.get_image().get_used_rect())
	return _regions[texture]

func _prop(texture: Texture2D, foot: Vector2, height: float, tint: Color = Color.WHITE) -> void:
	var region: Rect2 = _region(texture)
	var size: Vector2 = region.size * (height / maxf(region.size.y, 1.0))
	draw_texture_rect_region(texture, Rect2(foot-Vector2(size.x*0.5,size.y),size),region,tint)

func enter(id_value: StringName, _entry: StringName, states: Array[Dictionary]) -> void:
	for enemy in enemies:
		enemy.free()
	enemies.clear()
	for body in bodies:
		body.free()
	bodies.clear()
	projectiles.clear()
	area_id = id_value
	var map_info: Dictionary = rules.get_area(area_id)
	if coastal_map == null:
		coastal_map = load("res://scripts/areas/coastal_map.gd").new()
		coastal_map.name = "CoastalMap"
		add_child(coastal_map)
	coastal_map.visible = map_info.has("coastal_layout")
	if coastal_map.visible:
		coastal_map.configure(map_info)
	_building_sprite.visible = area_id == &"F"
	var paper: TextureRect = get_parent().get_node_or_null("PaperLayer/Paper") as TextureRect
	if paper != null:
		paper.texture = rain_texture if area_id == &"D" else (ruins_texture if area_id in [&"C", &"E"] else paper_texture)
	area_size = rules.get_area(area_id).size
	_wall(Rect2(-40,-40,area_size.x+80,40))
	_wall(Rect2(-40,area_size.y,area_size.x+80,40))
	_wall(Rect2(-40,0,40,area_size.y))
	_wall(Rect2(area_size.x,0,40,area_size.y))
	if map_info.has("coastal_layout"):
		for polygon in coastal_map.layout.solids:
			_polygon_wall(polygon)
		for prop in coastal_map.layout.props:
			if prop.has("body"):
				var footprint: Rect2 = prop.body
				footprint.position += prop.position
				_wall(footprint)
	if area_id == &"D" and not map_info.has("coastal_layout"):
		_wall(obstacle)
	exploration_navigation = null
	if area_id in [&"C",&"D",&"E"]:
		_build_exploration_navigation(map_info.size)
	for saved in states:
		if not saved.alive:
			continue
		var enemy: EnemyController = enemy_scene.instantiate()
		enemy.rules = rules
		enemy.player = player
		enemy.area = self
		enemy.position = saved.get("position",Vector2(800,280))
		add_child(enemy)
		enemy.configure(saved.spawn_id,saved.enemy_id,float(saved.hp))
		enemy.active = area_id != &"D" or map_info.has("coastal_layout")
		enemy.projectile_requested.connect(_projectile)
		enemies.append(enemy)
	font.font_names = PackedStringArray(["Malgun Gothic"])
	queue_redraw()

func _wall(rect: Rect2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 6
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)
	bodies.append(body)

func _polygon_wall(points: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 6
	var shape := CollisionPolygon2D.new()
	shape.polygon = points
	body.add_child(shape)
	add_child(body)
	bodies.append(body)

func capture_enemies() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy in enemies:
		result.append(enemy.capture())
	return result

func _projectile(origin: Vector2, direction: Vector2) -> void:
	projectiles.append({"position":origin,"direction":direction,"life":4.0})

func tick(dt: float) -> float:
	var incoming: float = 0.0
	if area_id == &"D" and player.position.x>=650:
		for enemy in enemies:
			enemy.active = true
	for index in range(projectiles.size()-1,-1,-1):
		var projectile: Dictionary = projectiles[index]
		var start: Vector2 = projectile.position
		var end: Vector2 = start+projectile.direction*150.0*dt
		var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = 5.0
		query.shape = circle
		query.transform = Transform2D(0,to_global(start))
		query.motion = end-start
		query.collision_mask = 1
		query.margin = 0.0
		var motion: PackedFloat32Array = get_world_2d().direct_space_state.cast_motion(query)
		var wall_hit: bool = motion[0]<1.0
		if wall_hit:
			end = start+(end-start)*motion[0]
		var hit: bool = Geometry2D.segment_intersects_circle(start,end,player.position,17.0)>=0.0
		projectile.position = end
		projectile.life -= dt
		if hit:
			incoming = maxf(incoming,10.0)
		if hit or wall_hit or projectile.life<=0.0:
			projectiles.remove_at(index)
	queue_redraw()
	return incoming

func next_waypoint(from: Vector2, goal: Vector2, radius: float) -> Vector2:
	if exploration_navigation != null:
		var start: Vector2i = Vector2i(from/80.0).clamp(Vector2i.ZERO,exploration_navigation.region.size-Vector2i.ONE)
		var finish: Vector2i = Vector2i(goal/80.0).clamp(Vector2i.ZERO,exploration_navigation.region.size-Vector2i.ONE)
		var route: PackedVector2Array = exploration_navigation.get_point_path(start,finish,true)
		return route[1] if route.size()>1 else from
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = Rect2i(0,0,28,14)
	grid.cell_size = Vector2(40,40)
	grid.offset = Vector2(20,20)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for x in range(28):
		for y in range(14):
			var point: Vector2 = Vector2(x*40+20,y*40+20)
			if obstacle.grow(radius).has_point(point) or point.x<radius or point.y<radius or point.x>area_size.x-radius or point.y>area_size.y-radius:
				grid.set_point_solid(Vector2i(x,y))
	var start: Vector2i = Vector2i(clampi(int(from.x/40),0,27),clampi(int(from.y/40),0,13))
	grid.set_point_solid(start,false)
	var requested: Vector2i = Vector2i(clampi(int(goal.x/40),0,27),clampi(int(goal.y/40),0,13))
	var destination: Vector2i = requested
	if grid.is_point_solid(destination):
		var queue: Array[Vector2i] = [requested]
		var seen: Dictionary = {requested:true}
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_front()
			if not grid.is_point_solid(cell) and not grid.get_id_path(start,cell).is_empty():
				destination = cell
				break
			for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
				var neighbor: Vector2i = cell+direction
				if grid.is_in_boundsv(neighbor) and not seen.has(neighbor):
					seen[neighbor] = true
					queue.append(neighbor)
	var path: PackedVector2Array = grid.get_point_path(start,destination)
	return path[1] if path.size()>1 else from

func _build_exploration_navigation(size_value: Vector2) -> void:
	exploration_navigation = AStarGrid2D.new()
	exploration_navigation.region = Rect2i(Vector2i.ZERO,Vector2i(ceil(size_value.x/80.0),ceil(size_value.y/80.0)))
	exploration_navigation.cell_size = Vector2(80,80)
	exploration_navigation.offset = Vector2(40,40)
	exploration_navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	exploration_navigation.update()
	for x in exploration_navigation.region.size.x:
		for y in exploration_navigation.region.size.y:
			var point := Vector2(x*80+40,y*80+40)
			var blocked: bool = false
			for polygon in coastal_map.layout.solids:
				for offset in [Vector2.ZERO,Vector2(35,0),Vector2(-35,0),Vector2(0,35),Vector2(0,-35)]:
					blocked = blocked or Geometry2D.is_point_in_polygon(point+offset,polygon)
			for prop in coastal_map.layout.props:
				if prop.has("body"):
					var body: Rect2 = prop.body
					body.position += prop.position
					blocked = blocked or body.grow(35.0).has_point(point)
			exploration_navigation.set_point_solid(Vector2i(x,y),blocked)

func show_restoration(value: bool) -> void:
	restored = value
	queue_redraw()

func _draw() -> void:
	var coastal: bool = rules != null and rules.get_area(area_id).has("coastal_layout")
	var ink_color: Color = Color("3B3430")
	ink_color.a = 0.38
	draw_rect(Rect2(Vector2.ZERO,area_size),Color(0.98,0.94,0.85,0.06))
	for foot in ([] if coastal else [Vector2(100,520),Vector2(area_size.x-120,510)]):
		_prop(flower_texture,foot,90 if area_id!=&"F" else 125,Color(1,1,1,0.8))
	for x in range(60,0 if coastal else int(area_size.x)-30,100):
		draw_dashed_line(Vector2(x,520),Vector2(x+65,515),Color(0.23,0.2,0.18,0.12),1.0,5.0)
	for side in ([] if coastal else [0,1]):
		var center: Vector2 = Vector2(0 if side==0 else area_size.x,280)
		var opened: bool = left_open if side==0 else right_open
		_prop(doorway_texture,center+Vector2(18 if side==0 else -18,45),125,Color.WHITE if opened else Color(0.55,0.55,0.6,1))
		draw_string(font,center+Vector2(18 if side==0 else -90,75),"← E" if side==0 else "E →",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("3B3430"))
	if area_id == &"A" and not coastal:
		_building(Vector2(300,210),"잉크 공방",true)
		_prop(npc_texture,Vector2(300,280),80)
		_prop(target_texture,Vector2(800,320),100)
		draw_string(font,Vector2(755,205),"연습 표적",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("3B3430"))
	if area_id == &"F":
		_building(Vector2(720,235),"되찾은 꽃집" if restored else "색을 잃은 꽃집",restored)
		if restored:
			_prop(npc_texture,Vector2(720,300),80)
	if area_id == &"D" and not coastal:
		var region: Rect2 = _region(pillar_texture)
		draw_texture_rect_region(pillar_texture,obstacle,region)
	var safe: Vector2 = rules.get_area(area_id).get("safe_point",Vector2(180,450)) if rules != null else Vector2(180,450)
	if area_id in [&"B",&"C",&"F"]:
		_prop(checkpoint_texture,safe,105)
		draw_arc(safe,26,0,TAU,40,Color(0.85,0.6,0.2,0.4),1.0,true)
		draw_string(font,safe+Vector2(-42,48),"E 귀환점",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("3B3430"))
	for projectile in projectiles:
		draw_circle(projectile.position,5.0,Color("8D3154"))

func _building(center: Vector2, title: String, colored: bool) -> void:
	var size: Vector2 = _building_sprite.region_rect.size
	_building_sprite.scale = Vector2.ONE * (235.0 / maxf(size.y,1.0))
	_building_sprite.position = center+Vector2(0,40)-Vector2(0,117.5)
	_building_sprite.material = null if colored else _unrestored_material
	draw_string(font,center+Vector2(-35,-190),title,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("3B3430"))
