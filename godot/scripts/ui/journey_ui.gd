class_name JourneyUI
extends CanvasLayer

signal interaction_requested(action: StringName)
signal pause_requested(value: bool)
signal movement_requested(value: Vector2)
signal attack_requested(value: bool)
signal skill_requested(id: String)

const SCENES: Dictionary = {
	"menu": preload("res://scenes/ui/MainMenu.tscn"),
	"hud": preload("res://scenes/ui/HUD.tscn"),
	"pause": preload("res://scenes/ui/PauseMenu.tscn"),
	"shop": preload("res://scenes/ui/Shop.tscn"),
	"confirm": preload("res://scenes/ui/ConfirmDialog.tscn")
}
const PAPER: Texture2D = preload("res://assets/world/paper-arena.png")
var settings_values: Dictionary = {"ui_scale": 1.0, "mute": false}
var _views: Dictionary = {}
var _theme: Theme
var _modal: String = ""
var _dialog_kind: StringName = &""
var _settings_return: String = "menu"
var _menu_has_save: bool = false
var _ink_status: String = ""
var _toast_text: String = ""
var _toast_remaining: float = 0.0
var _hp: Label
var _ink: Label
var _wealth: Label
var _tool: Label
var _goal: Label
var _status: Label
var _ink_bar: ProgressBar
var _ink_bottle: TextureRect
var _hud_stats: VBoxContainer
var _hud_goal: VBoxContainer
var _pause_button: Button
var _stats_paper: ColorRect
var _wallet_paper: ColorRect
var _goal_text: String = "공방에서 이동과 그리기를 배워 보세요"
var _state: Dictionary = {}
var _hp_bar: ProgressBar
var _portrait: TextureRect
var _region_banner: Label
var _region_remaining: float = 0.0
var _last_region: String = ""
var _joystick: Control
var _attack: Control
var _flower_skill: Control
var _paint_skill: Control
var _spring_skill: Control
var _brush: Control
var _pencil: Control
var _map_button: Control
var _bag_button: Control
var _interact_button: Control
var _mini_map: Control
var _status_back: TextureRect
var _goal_back: TextureRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_theme = preload("res://resources/ui/inkland_theme.tres").duplicate(true)
	_install_button_art()
	for key in SCENES:
		var view: Control = SCENES[key].instantiate()
		view.theme = _theme
		view.hide()
		add_child(view)
		_views[key] = view
	_build_hud()
	_views.hud.show()
	get_viewport().size_changed.connect(_layout_hud)

func _process(delta: float) -> void:
	_region_remaining = maxf(0.0,_region_remaining-delta)
	if _region_banner != null:
		_region_banner.visible = _region_remaining > 0.0 and not has_modal()
	if _toast_remaining > 0.0:
		_toast_remaining = maxf(0.0, _toast_remaining - delta)
		_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not InputMap.has_action("pause") or not event.is_action_pressed("pause") or event.is_echo():
		return
	if _modal in ["pause", "shop"]:
		get_viewport().set_input_as_handled()
		_emit_action(&"resume")
	elif _modal == "confirm" and _dialog_kind == &"settings":
		get_viewport().set_input_as_handled()
		if _settings_return == "menu":
			show_menu(_menu_has_save)
		else:
			_emit_action(&"resume")

func _label(text: String, size_value: int = 0) -> Label:
	var item := Label.new()
	item.text = text
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if size_value > 0:
		item.set_meta("base_font_size", size_value)
		var scaled: int = size_value if size_value >= 70 else int(size_value * clampf(float(settings_values.ui_scale), 1.0, 1.5))
		item.add_theme_font_size_override("font_size", scaled)
	return item

func _button(parent: Control, text: String, action: StringName, disabled_value: bool = false) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size.y = 55.0
	item.disabled = disabled_value
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.pressed.connect(_emit_action.bind(action))
	parent.add_child(item)
	_apply_button_art(item)
	return item

func _optional_texture(path: String, fallback: Texture2D = null) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else fallback

func _trimmed_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var image: Image = texture.get_image()
	if image == null:
		return texture
	var region: Rect2i = image.get_used_rect()
	if region.size == Vector2i.ZERO:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(region)
	return atlas

func _install_button_art() -> void:
	_theme.set_color("font_hover_color", "Button", Color(0.09, 0.20, 0.48))
	_theme.set_color("font_pressed_color", "Button", Color(0.09, 0.20, 0.48))

func _apply_button_art(button: Button) -> void:
	var source: Texture2D = _optional_texture("res://assets/ui/button-paper.png")
	if source == null:
		return
	# Measured alpha > 16 core; faint export glow extends to y708.
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = Rect2(18, 204, 2135, 316)
	var empty := StyleBoxEmpty.new()
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		empty.set_content_margin(side, 20.0)
	for side in [SIDE_TOP, SIDE_BOTTOM]:
		empty.set_content_margin(side, 10.0)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, empty)
	var paper := TextureRect.new()
	paper.texture = texture
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.show_behind_parent = true
	button.add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state in ["font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color(0.953, 0.898, 0.788))
	button.mouse_entered.connect(_refresh_button_art.bind(button, paper))
	button.mouse_exited.connect(_refresh_button_art.bind(button, paper))
	button.focus_entered.connect(_refresh_button_art.bind(button, paper))
	button.focus_exited.connect(_refresh_button_art.bind(button, paper))
	_refresh_button_art(button, paper)

func _refresh_button_art(button: Button, paper: TextureRect) -> void:
	if button.disabled:
		paper.modulate = Color(1, 1, 1, 0.8)
	elif button.has_focus() or button.is_hovered():
		paper.modulate = Color(0.08, 0.25, 0.9)
	else:
		paper.modulate = Color.WHITE

func _emit_action(action: StringName) -> void:
	if action == &"resume":
		pause_requested.emit(false)
	interaction_requested.emit(action)

func _clear(view: Control) -> void:
	for child in view.get_children():
		view.remove_child(child)
		child.queue_free()

func _open(name_value: String) -> Control:
	reset_controls()
	for key in _views:
		if key != "hud":
			_views[key].hide()
	_modal = name_value
	_dialog_kind = &""
	var view: Control = _views[name_value]
	_clear(view)
	view.show()
	# Native touch _input runs before the modal's GUI blocker.
	_views.hud.hide()
	return view

func _panel(name_value: String, title: String, wide: bool = false) -> VBoxContainer:
	var view: Control = _open(name_value)
	var dim := ColorRect.new()
	dim.color = Color(0.23, 0.20, 0.18, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	view.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(800 if wide else 580, 0)
	center.add_child(panel)
	var panel_source: Texture2D = _optional_texture("res://assets/ui/paper-panel.png")
	if panel_source != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = panel_source
		atlas.region = Rect2(39, 36, 1458, 917)
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var artwork := TextureRect.new()
		artwork.texture = atlas
		artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		artwork.stretch_mode = TextureRect.STRETCH_SCALE
		artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
		artwork.show_behind_parent = true
		panel.add_child(artwork)
		artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 90 if wide else 65)
	margin.add_theme_constant_override("margin_right", 60 if wide else 45)
	margin.add_theme_constant_override("margin_top", 110 if wide else 80)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	margin.add_child(content)
	var heading := _label(title, 34)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	return content

func _focus(item: Button) -> void:
	if not item.disabled:
		_focus_if_visible.call_deferred(item)

func _focus_if_visible(item: Variant) -> void:
	if is_instance_valid(item) and item is Button and item.is_inside_tree() and item.is_visible_in_tree():
		item.grab_focus()

func show_menu(has_save: bool) -> void:
	_menu_has_save = has_save
	var view: Control = _open("menu")
	var background := TextureRect.new()
	_install_button_art()
	background.texture = _optional_texture("res://assets/world/menu-illustration.png", PAPER)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title_art: Texture2D = _trimmed_texture(_optional_texture("res://assets/ui/title.png"))
	if title_art != null:
		var title := TextureRect.new()
		title.texture = title_art
		title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.add_child(title)
		title.position = Vector2(60, 45)
		title.size = Vector2(460, 170)
	else:
		var title := _label("INKLAND", 70)
		var serif := SystemFont.new()
		serif.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Georgia"])
		serif.font_weight = 700
		title.add_theme_font_override("font", serif)
		view.add_child(title)
		title.position = Vector2(70, 112)
	var subtitle := _label("빼앗긴 색을 되찾는 여정", 18)
	view.add_child(subtitle)
	subtitle.position = Vector2(76, 220)
	var column := VBoxContainer.new()
	column.position = Vector2(70, 270)
	column.custom_minimum_size.x = 350
	column.add_theme_constant_override("separation", 14)
	view.add_child(column)
	var continued: Button = _button(column, "이어하기", &"continue", not has_save)
	var fresh: Button = _button(column, "새 여정", &"new_game")
	_button(column, "설정", &"settings")
	_button(column, "종료", &"quit")
	var footer_paper := _quiet_paper(view)
	footer_paper.position = Vector2(62, 614)
	footer_paper.size = Vector2(410, 44)
	var footer := _label("WASD 이동 · 마우스로 그리기", 16)
	footer.add_theme_constant_override("outline_size", 0)
	view.add_child(footer)
	footer.position = Vector2(70, 620)
	footer.size.x = 395
	_focus(continued if has_save else fresh)

func show_pause() -> void:
	var content: VBoxContainer = _panel("pause", "잠시 붓을 내려놓고")
	_focus(_button(content, "계속", &"resume"))
	_button(content, "설정", &"settings")
	_button(content, "저장 후 메뉴", &"save_menu")

func show_shop(owned: bool, wallet: int) -> void:
	var content: VBoxContainer = _panel("shop", "공방 · 화구 카탈로그")
	content.add_child(_label("마을 지갑: %d 회수 잉크" % wallet))
	content.add_child(_label("연필 · 좁게, 강하게"))
	content.add_child(_label("가격 60 · 붓과 다른 가는 선을 그려 보세요", 18))
	var buy: Button = _button(content, "보유 중" if owned else "연필 구매 · 60", &"buy_pencil", owned or wallet < 60)
	if not owned and wallet < 60:
		content.add_child(_label("회수 잉크가 부족해요", 18))
	var back: Button = _button(content, "공방으로 돌아가기", &"resume")
	_focus(back if buy.disabled else buy)

func show_confirmation(kind: StringName, text: String) -> void:
	var content: VBoxContainer = _panel("confirm", "저장 버전 확인" if kind == &"unsupported" else "여정을 확인해 주세요")
	_dialog_kind = kind
	var body: Label = _label(text)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 500
	content.add_child(body)
	if kind == &"unsupported":
		_focus(_button(content, "취소 · 메뉴로 돌아가기", &"cancel_new"))
		return
	var elite: bool = kind == &"elite"
	_button(content, "정예 뜰로 들어가기" if elite else "새로운 여정 시작", &"confirm_elite" if elite else &"confirm_new")
	_focus(_button(content, "취소", &"cancel_elite" if elite else &"cancel_new"))

func show_settings(settings: Dictionary) -> void:
	_settings_return = _modal
	settings_values = {"ui_scale": float(settings.get("ui_scale", 1.0)), "mute": bool(settings.get("mute", false))}
	_theme.default_font_size = int(20.0 * clampf(settings_values.ui_scale, 1.0, 1.5))
	var content: VBoxContainer = _panel("confirm", "설정", true)
	_dialog_kind = &"settings"
	if _settings_return == "menu":
		_views.menu.show()
		_views.hud.hide()
	content.add_child(_label("글자 크기"))
	var size_choice := OptionButton.new()
	for value in [100, 125, 150]:
		size_choice.add_item("%d%%" % value)
	size_choice.selected = [1.0, 1.25, 1.5].find(settings_values.ui_scale)
	if size_choice.selected < 0:
		size_choice.selected = 0
	size_choice.item_selected.connect(func(index: int) -> void: settings_values.ui_scale = [1.0, 1.25, 1.5][index])
	content.add_child(size_choice)
	var mute := CheckButton.new()
	mute.text = "소리 끄기"
	mute.button_pressed = settings_values.mute
	mute.toggled.connect(func(value: bool) -> void: settings_values.mute = value)
	content.add_child(mute)
	_focus(_button(content, "설정 저장", &"settings_apply"))

func show_save_error(text: String) -> void:
	var content: VBoxContainer = _panel("confirm", "저장 실패")
	_dialog_kind = &"save_error"
	var body: Label = _label(text)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 500
	content.add_child(body)
	content.add_child(_label("현재 여정을 유지했어요. 저장을 다시 시도해 주세요.", 18))
	_focus(_button(content, "다시 시도", &"retry_save"))

func show_result(result: Dictionary) -> void:
	var reason: String = String(result.get("reason", ""))
	if not bool(result.get("ok", false)):
		if reason == "save_failed":
			show_save_error("저장하지 못했어요 · 다시 시도")
		else:
			_toast_text = {"missing_funds": "회수 잉크가 부족해요", "insufficient_ink": "회수 잉크가 부족해요", "locked": "아직 열리지 않은 길이에요", "missing_tool": "공방에서 연필을 구매해 주세요", "corrupt_save": "저장 파일을 읽지 못했어요", "ink_low": "잉크 부족 · 손을 떼어 충전", "range": "공격 범위 밖 · 손을 떼면 충전", "interaction_hint": "주민·문·귀환점 가까이에서\nE를 눌러 주세요", "elite_required": "정예를 물리친 뒤 꽃집에 색을 돌려주세요", "already_restored": "꽃집에 이미 색이 돌아왔어요", "already_owned": "이미 보유한 연필이에요"}.get(reason, "지금은 이 행동을 할 수 없어요")
			_toast_remaining = 3.0
	else:
		var message: String = {"restored": "꽃집에 색이 돌아왔어요\n금빛 귀환점에서 E", "flower_story": "정원지기: 꽃들이 다시 피었어요.\n다음 여정도 함께해요."}.get(reason, "")
		if not message.is_empty():
			_toast_text = message
			_toast_remaining = 3.0
	_update_status()

func _update_status() -> void:
	if _status != null:
		_status.text = _toast_text if _toast_remaining > 0.0 else (_ink_status if _ink_status.begins_with("잉크가") or _ink_status.begins_with("공격 범위") else "")

func _build_hud() -> void:
	var hud: Control = _views.hud
	_status_back = _hud_paper(hud)
	_goal_back = _hud_paper(hud)
	_mini_map = preload("res://scripts/ui/mini_map.gd").new()
	_mini_map.name = "MiniMap"
	hud.add_child(_mini_map)
	_portrait = TextureRect.new()
	var face := AtlasTexture.new()
	face.atlas = load("res://assets/characters/watercolor-v8/idle.png")
	face.region = Rect2(68,4,160,150)
	face.filter_clip = true
	_portrait.texture = face
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_portrait)
	_hp = _label("체력 100",16)
	_ink = _label("잉크 100",16)
	hud.add_child(_hp)
	hud.add_child(_ink)
	_hp_bar = _gauge(hud,"HealthBar",Color("bb7568"))
	_ink_bar = _gauge(hud,"InkBar",Color("77a9a9"))
	_wealth = _label("",18)
	_wealth.hide()
	hud.add_child(_wealth)
	_tool = _label("",18)
	_tool.hide()
	hud.add_child(_tool)
	_goal = _label("",16)
	_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_goal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_goal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_goal)
	_region_banner = _label("",23)
	_region_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(_region_banner)
	_status = _label("",16)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(_status)
	_joystick = preload("res://scripts/ui/virtual_joystick.gd").new()
	_joystick.name = "Joystick"
	_joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	_joystick.direction_changed.connect(func(value: Vector2): movement_requested.emit(value))
	hud.add_child(_joystick)
	_attack = _hud_action(hud,"Attack","공격",Vector2(104,104),Color("c0d2c1"))
	_attack.held_changed.connect(func(value: bool): attack_requested.emit(value))
	_flower_skill = _hud_action(hud,"FlowerSkill","꽃물결",Vector2(76,76),Color("dfbbc6"))
	_flower_skill.icon = "flower"
	_flower_skill.activated.connect(func(): skill_requested.emit("flower"))
	_paint_skill = _hud_action(hud,"PaintSkill","물감탄",Vector2(76,76),Color("b7cce3"))
	_paint_skill.icon = "paint"
	_paint_skill.activated.connect(func(): skill_requested.emit("paint"))
	_spring_skill = _hud_action(hud,"SpringSkill","색의 샘",Vector2(76,76),Color("b5d9d0"))
	_spring_skill.icon = "spring"
	_spring_skill.activated.connect(func(): skill_requested.emit("spring"))
	_brush = _hud_action(hud,"Brush","붓",Vector2(66,66),Color("d3e0cd"))
	_brush.activated.connect(func(): interaction_requested.emit(&"select_brush"))
	_pencil = _hud_action(hud,"Pencil","연필",Vector2(66,66),Color("e5d2ba"))
	_pencil.activated.connect(func(): interaction_requested.emit(&"select_pencil"))
	_map_button = _hud_action(hud,"Map","지도",Vector2(54,54),Color("e8dfc6"))
	_map_button.activated.connect(_open_map)
	_bag_button = _hud_action(hud,"Bag","가방",Vector2(54,54),Color("e8dfc6"))
	_bag_button.activated.connect(_open_bag)
	var menu := Button.new()
	menu.name = "Menu"
	menu.text = "☰"
	menu.custom_minimum_size = Vector2(54,54)
	menu.pressed.connect(_pause_button_pressed)
	hud.add_child(menu)
	for state_name in ["normal","hover","pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("e8dfc6") if state_name == "normal" else Color("c5d6c4")
		style.set_corner_radius_all(27)
		style.set_border_width_all(1)
		style.border_color = Color("84927b")
		menu.add_theme_stylebox_override(state_name,style)
	_pause_button = menu
	_interact_button = _hud_action(hud,"Interact","대화",Vector2(64,64),Color("d6e3cf"))
	_interact_button.activated.connect(func(): interaction_requested.emit(&"interact"))
	_interact_button.hide()
	_layout_hud()

func _hud_action(parent: Control, node_name: String, title: String, extent: Vector2, color: Color) -> Control:
	var item = preload("res://scripts/ui/touch_action.gd").new()
	item.name = node_name
	item.caption = title
	item.icon = {"FlowerSkill":"flower","PaintSkill":"paint","SpringSkill":"spring"}.get(node_name,"")
	item.tint = color
	item.size = extent
	parent.add_child(item)
	return item

func _hud_paper(parent: Control) -> TextureRect:
	var paper := TextureRect.new()
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/ui/button-paper.png")
	texture.region = Rect2(18,204,2135,316)
	paper.texture = texture
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(paper)
	return paper

func update_minimap(id: StringName, info: Dictionary, point: Vector2) -> void:
	_mini_map.update_map(id,info,point)

func _gauge(parent: Control, node_name: String, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = node_name
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.show_percentage = false
	bar.value = 100
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.90,0.87,0.76,0.60)
	base.set_corner_radius_all(5)
	base.border_color = Color(0.46,0.49,0.42,0.35)
	base.set_border_width_all(1)
	var fill: StyleBoxFlat = base.duplicate()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background",base)
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	return bar

func _quiet_paper(parent: Control) -> ColorRect:
	var paper := ColorRect.new()
	paper.color = Color(0.953,0.898,0.788,0.84)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(paper)
	return paper

func reset_controls() -> void:
	for item in [_joystick,_attack,_flower_skill,_paint_skill,_spring_skill,_brush,_pencil,_map_button,_bag_button,_interact_button]:
		if item != null:
			item.reset()

func _pause_button_pressed() -> void:
	show_pause()
	pause_requested.emit(true)

func _open_bag() -> void:
	pause_requested.emit(true)
	var content: VBoxContainer = _panel("confirm","여행 가방")
	content.add_child(_label("원정 잉크  %d   ·   마을 지갑  %d" % [int(_state.get("run_ink",0)),int(_state.get("wallet_ink",0))]))
	var owned: bool = "pencil" in _state.get("owned_tools",["brush"])
	content.add_child(_label("화구  ·  붓"+(" / 연필" if owned else "")))
	content.add_child(_label("현재 목표  ·  "+_goal_text,18))
	_focus(_button(content,"닫기",&"resume"))

func _open_map() -> void:
	pause_requested.emit(true)
	var content: VBoxContainer = _panel("confirm","색을 되찾는 길")
	content.add_child(_label("현재 위치  ·  "+_last_region))
	content.add_child(_label("해안 마을 → 물빛 해안 → 첫 공터",18))
	content.add_child(_label("갈림 공터 → 정예 뜰 → 꽃집",18))
	content.add_child(_label("금빛 귀환점에서 마을로 돌아올 수 있어요",18))
	_focus(_button(content,"닫기",&"resume"))

func set_interaction(title: String, screen: Vector2) -> void:
	_interact_button.visible = not title.is_empty() and not has_modal()
	if not _interact_button.visible:
		_interact_button.reset()
	if title.is_empty():
		return
	_interact_button.get_child(0).text = title
	var extent: Vector2 = get_viewport().get_visible_rect().size
	_interact_button.position = Vector2(clampf(screen.x-32,320,extent.x-260),clampf(screen.y-105,125,extent.y-240))

func _layout_hud() -> void:
	if _hp == null:
		return
	var extent: Vector2 = get_viewport().get_visible_rect().size
	_status_back.position = Vector2(10,8)
	var row_height: float = 26.0*clampf(float(settings_values.ui_scale),1.0,1.5)
	var panel_height: float = 51.0+row_height*2.0
	_status_back.size = Vector2(300,panel_height)
	_goal_back.position = Vector2(extent.x-368,78)
	_goal_back.size = Vector2(354,46)
	_mini_map.position = Vector2(18,panel_height+20)
	_mini_map.size = Vector2(206,150)
	_portrait.position = Vector2(18,16)
	_portrait.size = Vector2(66,66)
	_hp.position = Vector2(96,16)
	_hp.size = Vector2(190,22)
	_hp_bar.position = Vector2(96,16+row_height)
	_hp_bar.size = Vector2(184,10)
	_ink.position = Vector2(96,31+row_height)
	_ink.size = Vector2(190,22)
	_ink_bar.position = Vector2(96,31+row_height*2.0)
	_ink_bar.size = Vector2(184,8)
	_map_button.position = Vector2(extent.x-190,18)
	_bag_button.position = Vector2(extent.x-130,18)
	_pause_button.position = Vector2(extent.x-70,18)
	_pause_button.size = Vector2(54,54)
	_goal.position = Vector2(extent.x-348,88)
	_goal.size = Vector2(312,26)
	_region_banner.position = Vector2(extent.x*0.5-210,25)
	_region_banner.size = Vector2(420,38)
	_joystick.position = Vector2(28,extent.y-204)
	_joystick.size = Vector2(172,172)
	_attack.position = Vector2(extent.x-140,extent.y-142)
	_flower_skill.position = Vector2(extent.x-242,extent.y-206)
	_paint_skill.position = Vector2(extent.x-310,extent.y-136)
	_spring_skill.position = Vector2(extent.x-220,extent.y-294)
	_brush.position = Vector2(extent.x-218,extent.y-102)
	_pencil.position = Vector2(extent.x-152,extent.y-218)
	_status.position = Vector2(extent.x*0.5-245,extent.y-64)
	_status.size = Vector2(490,48)

func _scale_labels(node: Node, scale_value: float) -> void:
	if node is Label and node.has_meta("base_font_size"):
		var base: int = int(node.get_meta("base_font_size"))
		node.add_theme_font_size_override("font_size", base if base >= 70 else int(base * scale_value))
	for child in node.get_children():
		_scale_labels(child, scale_value)

func render_state(snapshot: Dictionary) -> void:
	_state = snapshot.duplicate(true)
	if _hp == null:
		return
	var hp: int = int(snapshot.get("hp", 100))
	
	_hp.text = "체력 %d" % hp
	_hp_bar.value = hp
	_wealth.text = "회수 잉크 · 원정 %d / 지갑 %d" % [int(snapshot.get("run_ink", 0)), int(snapshot.get("wallet_ink", 0))]
	var owned: bool = "pencil" in snapshot.get("owned_tools", ["brush"])
	var selected: String = String(snapshot.get("tool", "brush"))
	_pencil.set("disabled",not owned)
	_pencil.get_child(0).text = "연필" if owned else "미보유"
	_brush.set("tint",Color("adc9b5") if selected == "brush" else Color("e8dfc6"))
	_pencil.set("tint",Color("d9bfa1") if selected == "pencil" else Color("e8dfc6"))
	_brush.queue_redraw()
	_pencil.queue_redraw()
	_tool.text = ("● 1 붓" if selected == "brush" else "○ 1 붓") + " / " + ("● 2 연필" if selected == "pencil" else "○ 2 연필") + ("" if owned else " · 미보유")
	var settings: Dictionary = snapshot.get("settings", settings_values)
	var scale_changed: bool = not is_equal_approx(float(settings.get("ui_scale",1.0)),float(settings_values.ui_scale))
	settings_values = {"ui_scale": float(settings.get("ui_scale", 1.0)), "mute": bool(settings.get("mute", false))}
	if scale_changed:
		_theme.default_font_size = int(20.0 * clampf(settings_values.ui_scale, 1.0, 1.5))
		_scale_labels(self, clampf(settings_values.ui_scale, 1.0, 1.5))
		_layout_hud()
	if bool(snapshot.get("flower_restored", false)) and owned and bool(snapshot.get("pencil_test_completed", false)):
		set_goal("첫 여정 완료 · 다음 길은 준비 중")

func render_ink(current: float, maximum: float, phase: StringName) -> void:
	if _ink == null:
		return
	var names: Dictionary = {"ready": "가득 참", "attacking": "그리는 중", "held_empty": "잉크가 비었어요 · 손을 떼어 충전", "held_outside": "공격 범위 밖 · 손을 떼면 충전", "waiting": "충전 대기", "recharging": "충전 중"}
	_ink.text = "잉크 %d" % int(ceil(current))
	_ink_status = names.get(String(phase), "")
	_update_status()
	_ink_bar.max_value = maximum
	_ink_bar.value = current

func render_skills(cooldowns: Dictionary, ink: float, casting: bool) -> void:
	var buttons: Dictionary = {"paint":_paint_skill,"flower":_flower_skill,"spring":_spring_skill}
	var titles: Dictionary = {"paint":"물감탄","flower":"꽃물결","spring":"색의 샘"}
	var costs: Dictionary = {"paint":12.0,"flower":20.0,"spring":30.0}
	for id in buttons:
		var button: Control = buttons[id]
		var remaining: float = float(cooldowns[id])
		button.set("disabled",casting or remaining > 0.0 or ink < float(costs[id]))
		button.get_child(0).text = "%.1f초" % remaining if remaining > 0.0 else ("잉크 부족" if ink < float(costs[id]) else titles[id])
		button.queue_redraw()

func set_goal(text: String) -> void:
	_goal_text = text
	if _goal != null:
		var pieces: PackedStringArray = text.split("  ·  ",true,1)
		_goal.text = pieces[-1]
		if pieces.size() > 1 and pieces[0] != _last_region:
			_last_region = pieces[0]
			_region_banner.text = _last_region
			_region_remaining = 3.0

func hide_modal() -> void:
	for key in _views:
		if key != "hud":
			_views[key].hide()
	_modal = ""
	_views.hud.show()

func has_modal() -> bool:
	return not _modal.is_empty()
