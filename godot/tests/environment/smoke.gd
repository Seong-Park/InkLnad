extends Node

func _ready() -> void:
	if not get_parent().has_node("DiskProbe") or not get_parent().has_node("LiveProbe"):
		push_error("Missing MCP probe nodes")
		get_tree().quit(1)
		return
	print("INK_LAND_MCP_SMOKE_PASS")
	get_tree().quit(0)
