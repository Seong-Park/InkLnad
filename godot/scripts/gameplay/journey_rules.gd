class_name JourneyRules
extends Resource

# Approved first-journey prototype values; one shared source for runtime and UI.
@export var player: Dictionary = {"hp": 100.0, "speed": 180.0, "radius": 12.0, "attack_radius": 180.0, "invulnerability": 0.75, "entry_protection": 0.75}
@export var ink: Dictionary = {"maximum": 100.0, "recharge_rate": 100.0 / 3.5, "delay": 0.5, "minimum_start": 1.0}
@export var camera: Dictionary = {"viewport": Vector2(1280, 720), "zoom": 1.0, "deadzone": Vector2(80, 50), "smoothing_seconds": 0.15}
@export var damage_interval: float = 0.25
@export var stamp_spacing: float = 4.0
@export var stamp_merge_distance: float = 2.0
@export var pencil_price: int = 60
@export var tutorial: Dictionary = {"move_distance": 120.0, "line_length": 80.0, "hold_seconds": 0.5, "recovered_ink": 10.0, "target_position": Vector2(800, 280)}
@export var interaction: Dictionary = {"radius": 64.0, "enemy_block_radius": 500.0, "exit_size": Vector2(60, 96), "transition_seconds": 0.2}
@export var save_interval: float = 5.0
@export var tools: Dictionary = {
	"brush": {"width": 32.0, "half_width": 16.0, "upkeep": 20.0, "length_cost": 0.04, "direct_damage": 6.0, "residual_damage": 2.0, "lifetime": 1.5, "damage_interval": 0.25},
	"pencil": {"width": 12.0, "half_width": 6.0, "upkeep": 14.0, "length_cost": 0.025, "direct_damage": 12.0, "residual_damage": 3.0, "lifetime": 1.0, "damage_interval": 0.25}
}
@export var enemies: Dictionary = {
	"drop": {"hp": 24.0, "radius": 14.0, "speed": 65.0, "contact_damage": 8.0, "contact_interval": 1.0, "reward": 8},
	"dash": {"hp": 48.0, "radius": 18.0, "speed": 45.0, "contact_damage": 8.0, "contact_interval": 1.0, "reward": 16, "detection_range": 250.0, "telegraph": 0.6, "dash_speed": 300.0, "dash_duration": 0.5, "recovery": 1.2, "dash_damage": 15.0},
	"blot": {"hp": 36.0, "radius": 16.0, "speed": 0.0, "contact_damage": 8.0, "contact_interval": 1.0, "reward": 12, "detection_range": 400.0, "shot_interval": 2.2, "telegraph": 0.5, "projectile_speed": 150.0, "projectile_radius": 5.0, "projectile_damage": 10.0, "projectile_lifetime": 4.0},
	"elite_dash": {"hp": 120.0, "radius": 26.0, "speed": 45.0, "contact_damage": 10.0, "contact_interval": 1.0, "reward": 50, "detection_range": 600.0, "telegraph": 0.8, "dash_speed": 280.0, "dash_duration": 0.7, "recovery": 1.5, "dash_damage": 18.0}
}
@export var areas: Dictionary = {
	"A": {"name": "수채화 해안 마을", "size": Vector2(2560,1792), "camera": "follow_2d", "coastal_layout": "A", "portals": {"east": Vector2(2400,1210)}, "spawns": [], "obstacles": [], "exits": {"east": "B"}, "entry_west": Vector2(870,820), "entry_east": Vector2(2260,1170), "start_position": Vector2(870,820), "npc_position": Vector2(630,640), "target_position": Vector2(650,1080), "east_condition": "tutorial_complete", "safe_point": Vector2(650,1180)},
	"B": {"name": "물빛 해안 필드", "size": Vector2(3072,2048), "camera": "follow_2d", "coastal_layout": "B", "portals": {"west": Vector2(230,780), "east": Vector2(2930,1190)}, "spawns": [], "obstacles": [], "exits": {"west": "A", "east": "C"}, "entry_west": Vector2(350,830), "entry_east": Vector2(2790,1190), "safe_point": Vector2(450,830)},
	"C": {"name": "첫 공터", "size": Vector2(1120, 560), "camera": "fixed", "spawns": [{"spawn_id": "c01", "enemy_id": "drop", "position": Vector2(650, 220)}, {"spawn_id": "c02", "enemy_id": "drop", "position": Vector2(780, 320)}, {"spawn_id": "c03", "enemy_id": "drop", "position": Vector2(880, 180)}], "obstacles": [], "exits": {"west": "B", "east": "D"}, "entry_west": Vector2(90, 280), "entry_east": Vector2(1030, 280), "east_condition": "area_cleared", "safe_point": Vector2(180, 450), "safe_condition": "area_cleared"},
	"D": {"name": "갈림 공터", "size": Vector2(1120, 560), "camera": "fixed", "spawns": [{"spawn_id": "d01", "enemy_id": "drop", "position": Vector2(850, 140)}, {"spawn_id": "d02", "enemy_id": "dash", "position": Vector2(900, 400)}, {"spawn_id": "d03", "enemy_id": "blot", "position": Vector2(980, 260)}], "obstacles": [Rect2(700, 180, 60, 100)], "exits": {"west": "C", "east": "E"}, "entry_west": Vector2(90, 280), "entry_east": Vector2(1030, 280), "activation_x": 650.0, "confirm_east": true, "path_grid": 40.0, "path_refresh": 0.25},
	"E": {"name": "정예 뜰", "size": Vector2(1120, 560), "camera": "fixed", "spawns": [{"spawn_id": "e01", "enemy_id": "elite_dash", "position": Vector2(800, 280)}], "obstacles": [], "exits": {"west": "D", "east": "F"}, "entry_west": Vector2(90, 280), "entry_east": Vector2(1030, 280), "exit_condition": "first_elite_defeated", "return_locked": true},
	"F": {"name": "꽃집", "size": Vector2(1120, 560), "camera": "fixed", "spawns": [], "obstacles": [], "exits": {"west": "E"}, "entry_west": Vector2(90, 280), "entry_east": Vector2(1030, 280), "restore_position": Vector2(720, 280), "safe_point": Vector2(180, 450), "restore_condition": "first_elite_defeated"}
}

func get_tool(tool_id: StringName) -> Dictionary:
	return tools.get(String(tool_id), {}).duplicate(true)

func get_enemy(enemy_id: StringName) -> Dictionary:
	return enemies.get(String(enemy_id), {}).duplicate(true)

func get_area(area_id: StringName) -> Dictionary:
	var info: Dictionary = areas.get(String(area_id), {}).duplicate(true)
	if area_id in [&"C",&"D",&"E"]:
		return preload("res://scripts/areas/exploration_layouts.gd").area(area_id,info)
	return preload("res://scripts/areas/world_dimensions.gd").expand(info) if info.has("coastal_layout") else info
