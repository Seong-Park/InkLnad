extends Node2D

const RIG := preload("res://scenes/characters/FoxFrontRig.tscn")
var rigs: Array[FoxFrontRig] = []
var paused := false
var slow := false
var elapsed := 0.0
var attack_clock := 0.0
var sequence := false
var sequence_clock := 0.0
var status: Label

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("f1ead8"))
	var source := Sprite2D.new()
	source.texture = FoxFrontRig.MASTER
	source.scale = Vector2.ONE*0.65
	source.position = Vector2(130,580)+Vector2(0,-244)*0.65
	add_child(source)
	for i in 4:
		var rig: FoxFrontRig = RIG.instantiate()
		rig.position = Vector2(385+255*i,580)
		rig.scale = Vector2.ONE*0.65
		add_child(rig)
		rigs.append(rig)
	rigs[0].neutral()
	rigs[1].play_state(&"idle")
	rigs[2].play_state(&"walk")
	rigs[3].play_state(&"attack")
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := Label.new()
	title.text = "정면 뼈대 비교 · 동일 원화 / 부품 / 크기"
	title.position = Vector2(28,22)
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("43554d"))
	ui.add_child(title)
	var controls := HBoxContainer.new()
	controls.position = Vector2(28,70)
	ui.add_child(controls)
	button(controls,"재생 / 일시정지",toggle_pause)
	button(controls,"느린 재생 0.25×",toggle_slow)
	button(controls,"대기 → 걷기 → 공격",toggle_sequence)
	button(controls,"중립 자세 겹치기",toggle_overlay)
	for i in 5:
		var label := Label.new()
		label.text = ["기준 원화","재조립 중립","대기","걷기 · 바닥 흐름","공격 / 전환"][i]
		label.position = Vector2(35+255*i,600)
		label.add_theme_color_override("font_color",Color("43554d"))
		ui.add_child(label)
	status = Label.new()
	status.position = Vector2(28,645)
	status.add_theme_color_override("font_color",Color("43554d"))
	ui.add_child(status)

func button(parent: Control,text: String,callback: Callable) -> void:
	var node := Button.new()
	node.text = text
	node.pressed.connect(callback)
	parent.add_child(node)

func toggle_pause() -> void:
	paused = not paused
	for rig in rigs: rig.animator.speed_scale = 0.0 if paused else (0.25 if slow else 1.0)

func toggle_slow() -> void:
	slow = not slow
	for rig in rigs: rig.animator.speed_scale = 0.0 if paused else (0.25 if slow else 1.0)

func toggle_overlay() -> void:
	var overlay := rigs[0].position.x != 130.0
	rigs[0].position.x = 130.0 if overlay else 385.0
	rigs[0].modulate.a = 0.5 if overlay else 1.0

func toggle_sequence() -> void:
	sequence = not sequence
	sequence_clock = 0.0
	rigs[3].play_state(&"idle" if sequence else &"attack")

func _process(delta: float) -> void:
	if rigs.is_empty(): return
	var step := 0.0 if paused else delta*(0.25 if slow else 1.0)
	elapsed += step
	attack_clock += step
	if sequence:
		sequence_clock += step
		if sequence_clock >= 5.2: sequence_clock = 0.0
		var target: StringName = &"idle" if sequence_clock < 2.0 else (&"walk" if sequence_clock < 4.0 else &"attack")
		if rigs[3].current_state != target and not (target == &"attack" and sequence_clock >= 4.8): rigs[3].play_state(target)
	elif attack_clock >= 1.6:
		attack_clock = 0.0
		rigs[3].play_state(&"attack")
	status.text = "정면 전용 검토 장면 · 플레이어 미교체 · %s · %.2f×" % ["일시정지" if paused else "재생 중",0.25 if slow else 1.0]
	queue_redraw()

func _draw() -> void:
	for i in 5:
		draw_line(Vector2(20+255*i,580),Vector2(235+255*i,580),Color("9a9c7b"),1.0)
	var offset := fmod(elapsed*24.0,24.0)
	for j in 8:
		var y := 520.0+float(j)*12.0+offset*0.5
		draw_line(Vector2(810,y),Vector2(995,y),Color(0.54,0.59,0.45,0.25),1.0)
