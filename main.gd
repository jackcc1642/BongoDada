extends Control

# 引用小马节点
@onready var pony_avatar: TextureRect = $PonyAvatar

#【UI节点引用】
@onready var hit_counter: Label = $UILayer/BottomBar/HitCounter
@onready var menu_btn: Button = $UILayer/BottomBar/MenuBtn

@onready var unlock_bubble: Button = $UILayer/UnlockBUbble
@onready var item_icon: TextureRect = $UILayer/UnlockBUbble/ItemIcon

@onready var float_int: PanelContainer = $UILayer/FloatHint
@onready var hint_label: Label = $UILayer/FloatHint/HintLabel


# 当前正在等待领取的奖励数据
var pending_reward_data = null


#【皮肤纹理引用 - 为拓展做准备】
# 预加载防止切换时卡顿
# 如果后续增加新皮肤，只需要在此定义 xxx_hands1, xxx_hands2 即可
var pony_hands1 = preload("res://assets/images/pony_hands11.png")
var pony_hands2 = preload("res://assets/images/pony_hands22.png")
var pony_keyboard = preload("res://assets/images/pony_keyboard.png")


#【当前皮肤状态】
# 默认使用第一套皮肤
var current_skin_hands1 = pony_hands1
var current_skin_hands2 = pony_hands2
var current_skin_keyboards = pony_keyboard


#【新增】记录当前是不是 hands1 状态
var is_hands1: bool = true
#【新增】停止敲击多长时间后，强制回到 IDLE 状态
var idle_timer: float = 0.0
## 0.15秒不敲键盘就回到 hands1
var idle_delay: float = 0.15 

#【新增】视觉保护器倒计时，防止同一帧内来回乱切
var visual_cooldown: float = 0.0
#【新增】锁定时间：0.03秒，保证屏幕一定能够输出
var min_visual_time: float = 0.03


func _ready() -> void:
	# 游戏开始时的发呆状态
	pony_avatar.texture = current_skin_hands1
	# 把小马形变的中心点放在底部中间，这样下压的时候，底部会固定在屏幕边缘
	pony_avatar.pivot_offset = Vector2(pony_avatar.size.x / 2.0, pony_avatar.size.y)

	# 游戏开始时隐藏 UI 控件
	unlock_bubble.visible = false
	float_int.visible = false
	hit_counter.text = str(Config.total_hits)

	# 游戏开始时，绑定气泡点击事件
	unlock_bubble.pressed.connect(_on_unlock_bubble_pressed)



func _process(delta: float) -> void:
	# 1. 处理视觉保护期倒计时
	if visual_cooldown > 0:
		visual_cooldown -= delta
	# 2. 处理发呆倒计时
	if idle_timer > 0:
		idle_timer -= delta
		if idle_timer <= 0:
			# 倒计时结束，强制回到 IDLE 状态
			is_hands1 = true
			pony_avatar.texture = pony_hands1
			pony_avatar.scale = Vector2(1.0, 1.0)

func _input(event: InputEvent) -> void:
	# 1. 退出通道
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	# 2. 核心监听: 检测是否键盘的敲击时间，并且排除长按产生的连续触发 (echo)
	if event is InputEventKey and not event.is_echo():
		if event.is_pressed():
			# 只有过了视觉保护期，才允许翻转状态
			if  visual_cooldown <= 0:
				is_hands1 = !is_hands1

				if is_hands1:
					pony_avatar.texture = pony_hands1
				else:
					pony_avatar.texture = pony_hands2
				
				# 重置视觉保护器，锁定当前状态
				visual_cooldown = min_visual_time

				# 计步器
				Config.total_hits += 1

				# 奖励检查
				check_unlocks()

			# 每次敲击都要重置 idle 倒计时
			idle_timer = idle_delay
			pony_avatar.scale = Vector2(1.05, 0.9)



#【解锁判定函数】
func check_unlocks() -> void:
	# 当前的敲击次数在配置表里
	if Config.unlcok_config.has(Config.total_hits):
		var reward_data = Config.unlcok_config[Config.total_hits]

		# 确保奖励没被领过
		if not Config.claimed_rewards.has(reward_data.id):
			# 记录当前待领取的奖励
			pending_reward_data = reward_data

			# 显示气泡和缩略图
			item_icon.texture = load(reward_data.icon)
			unlock_bubble.visible = true
			# 小动画
			unlock_bubble.scale = Vector2(0.1, 0.1)
			var tween := create_tween()
			tween.tween_property(unlock_bubble, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE)
		
		# 打印到控制台看看效果（后续我们可以把它做成游戏里的弹窗UI）
		print("达成目标: ", Config.total_hits, "次！")
		print("获得奖励: ", reward_data.get("reward_type"), reward_data.get("name"))
		print("-----------------------")

#【气泡点击逻辑】
