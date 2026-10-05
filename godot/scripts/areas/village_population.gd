extends RefCounted

static func definitions(guide: Vector2) -> Array[Dictionary]:
	var residents: Array[Dictionary] = [
		{"id":"craft-guide","role":"craft-master","art":"craft-master","position":guide,"height":84.0,"phase":4.0,"speech":"붓 끝에 색을 담아 보게."},
		{"id":"brush-seller","role":"tool-merchant","art":"tool-merchant","position":Vector2(1090,505),"phase":8.0,"speech":"오늘도 좋은 붓을 골라요."},
		{"id":"herbalist","role":"apothecary","art":"apothecary","position":Vector2(1450,600),"phase":13.0,"speech":"따뜻한 약초차 한 잔 어때요?"},
		{"id":"village-tailor","role":"tailor","art":"tailor","position":Vector2(760,940),"phase":18.0,"speech":"새 옷감을 펼쳐 볼까요?"},
		{"id":"tea-host","role":"tea-host","art":"tea-host","position":Vector2(1810,670),"phase":7.0,"speech":"잠시 쉬었다 가세요."},
		{"id":"tea-guest-one","role":"tea-guest","art":"tea-guest","position":Vector2(1720,640),"height":63.0,"phase":15.0,"speech":"바닷바람이 참 좋네요."},
		{"id":"tea-guest-two","role":"tea-guest","art":"tea-guest","position":Vector2(1800,850),"height":63.0,"flip_h":true,"tint":Color("f0f5ff"),"phase":20.0,"speech":"차 향이 은은하군요."},
		{"id":"plaza-friend-one","role":"chat-resident","art":"chat-resident","position":Vector2(1050,810),"phase":3.0,"speech":"해안에 색이 돌아왔대요."},
		{"id":"plaza-friend-two","role":"chat-resident","art":"chat-resident","position":Vector2(1130,825),"flip_h":true,"tint":Color("fff0de"),"phase":10.0,"speech":"내일은 꽃을 보러 갈까요?"},
		{"id":"basket-shopper","role":"basket-walker","art":"basket-walker","position":Vector2(820,820),"phase":5.0,"speech":"찻집에 들렀다 가야지.","route":PackedVector2Array([Vector2(820,820),Vector2(1060,890),Vector2(1230,840),Vector2(1060,890)])},
		{"id":"village-courier","role":"courier-walker","art":"courier-walker","position":Vector2(1480,900),"phase":17.0,"speech":"안료 배달 왔습니다!","route":PackedVector2Array([Vector2(1480,900),Vector2(1700,980),Vector2(1900,1070),Vector2(1700,980)])},
		{"id":"garden-keeper","role":"gardener","art":"gardener","position":Vector2(770,1150),"phase":21.0,"speech":"꽃도 물빛을 좋아하나 봐요."}
	]
	for index in 5:
		residents[index]["stroll"] = true
	return residents
