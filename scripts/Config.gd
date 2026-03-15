## Config.gd
extends Node


# 玩家数据
var total_hits: int = 0
var unlocked_skins: Array = ["base_pony"] # 默认已拥有的皮肤
var claimed_rewards: Array = [] # 记录已经点过气泡领取的奖励，避免重复弹



# 策划配表
var unlock_config = {
	10:{
		"reward_type": "skin",
		"id": "skin_pony_lv2",
		"name": "小马进化2",
		"icon": "res://assets/images/pony_hands11.png"
	},

	200:{
		"reward_type": "skin",
		"id": "skin_pony_cyber",
		"name": "赛博小马",
		"icon": "res://assets/images/pony_hands22.png"
	}
}

# 皮肤资源参数库
var skins = {
	"base_pony":{
		"name": "经典小马",
		# 1. 资源映射解耦
		"hands1": "res://assets/images/pony_hands11.png",
		"hands2": "res://assets/images/pony_hands22.png",
		"keyboard": "res://assets/images/pony_keyboard.png",

		# 2. 独立参数调优
		# 小马身体参数
		"avatar_offset": Vector2(0, 0),
		"avatar_scale": Vector2(1.0, 1.0),
		"avatar_rotation": 0.0, 	# 角度
		
		# 键盘微调
		"keyboard_offset": Vector2(0, 0),
		"keyboard_scale": Vector2(1.0, 1.0),
		"keyboard_rotation": 2.1
	},
	"skin_pony_lv2":{
		"name": "小马进化2",
		"hands1": "res://assets/images/pony_hands11.png",
		"hands2": "res://assets/images/pony_hands22.png",
		"keyboard": "res://assets/images/pony_keyboard.png",

		"avatar_offset": Vector2(0, 0),
		"avatar_scale": Vector2(1.0, 1.0),
		"avatar_rotation": 0.0, 	# 角度

		"keyboard_offset": Vector2(0, 0),
		"keyboard_scale": Vector2(1.0, 1.0),
		"keyboard_rotation": 0.0
	}
}

# 记录当前正在使用的皮肤 ID
var current_skin_id: String = "base_pony"