extends Node


# 玩家数据
var total_hits: int = 0
var unlocked_skins: Array = ["base_pony"] # 默认已拥有的皮肤
var claimed_rewards: Array = [] # 记录已经点过气泡领取的奖励，避免重复弹



# 策划陪标
var unlcok_config = {
	50:{
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