## main.gd
extends Control

# 引用小马节点
@onready var pony_avatar: TextureRect = $PonyAvatar
@onready var static_base: TextureRect = $StaticBase

#【UI节点引用】
@onready var hit_counter: Button = $UILayer/BottomBar/HitCounter
@onready var menu_btn: Button = $UILayer/BottomBar/MenuBtn

@onready var menu_panel: PanelContainer = $UILayer/MenuPanel
@onready var menu_hits_label: Label = $UILayer/MenuPanel/VBoxContainer/MenuHitsLabel
@onready var skin_switch_btn: Button = $UILayer/MenuPanel/VBoxContainer/SkinSwitchBtn

@onready var unlock_bubble: Button = $UILayer/UnlockBUbble
@onready var item_icon: TextureRect = $UILayer/UnlockBUbble/ItemIcon

@onready var float_hint: PanelContainer = $UILayer/FloatHint
@onready var hint_label: Label = $UILayer/FloatHint/HintLabel


# 当前正在等待领取的奖励数据
var pending_reward_data = null


#【皮肤纹理引用 - 为拓展做准备】
# 预加载防止切换时卡顿


#【当前皮肤状态】
# 默认使用第一套皮肤,动态变量
var current_skin_hands1: Texture2D
var current_skin_hands2: Texture2D
var current_skin_keyboard: Texture2D
# 记录基础缩放值
var base_avatar_scale: Vector2 = Vector2(1.0, 1.0)

# 记录编辑器初始位置
var base_avatar_pos: Vector2
var base_keyboard_pos: Vector2

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
	Config.load_game()
	# 在修改前，先记录编辑器里的原始坐标
	base_avatar_pos = pony_avatar.position
	base_keyboard_pos = static_base.position

	# 游戏开始时隐藏 UI 控件
	unlock_bubble.visible = false
	float_hint.visible = false
	hit_counter.text = str(Config.total_hits)

	# 游戏开始时，绑定点击事件
	unlock_bubble.pressed.connect(_on_unlock_bubble_pressed)
	menu_btn.pressed.connect(_on_menu_btn_pressed)
	skin_switch_btn.pressed.connect(_on_skin_switch_btn_pressed)

	# 游戏开始时，读取 Config 里的当前皮肤并应用
	change_skin(Config.current_skin_id)
	check_unlocks()

	# 游戏开始时的发呆状态
	pony_avatar.texture = current_skin_hands1
	# 把小马形变的中心点放在底部中间，这样下压的时候，底部会固定在屏幕边缘
	pony_avatar.pivot_offset = Vector2(pony_avatar.size.x / 2.0, pony_avatar.size.y)

func change_skin(skin_id: String) -> void:
	if not Config.skins.has(skin_id):
		return
	var skin_data = Config.skins[skin_id]

	# 1. 动态加载图片资源
	current_skin_hands1 = load(skin_data.hands1)
	current_skin_hands2 = load(skin_data.hands2)
	static_base.texture = load(skin_data.keyboard)

	pony_avatar.texture = current_skin_hands1
	is_hands1 = true

	# 2. 应用独立参数
	# 键盘参数
	static_base.position = base_keyboard_pos + skin_data.keyboard_offset
	static_base.scale = skin_data.keyboard_scale
	static_base.rotation_degrees = skin_data.keyboard_rotation

	# 小马参数
	pony_avatar.position = base_avatar_pos + skin_data.avatar_offset
	pony_avatar.rotation_degrees = skin_data.avatar_rotation

	base_avatar_scale = skin_data.avatar_scale
	pony_avatar.scale = base_avatar_scale
	
	
	# 重新计算中心点
	pony_avatar.pivot_offset = Vector2(current_skin_hands1.get_width() / 2.0, current_skin_hands1.get_height())
	var kb_tex = static_base.texture
	if kb_tex != null:
		static_base.pivot_offset = Vector2(kb_tex.get_width() / 2.0, kb_tex.get_height())

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
			pony_avatar.texture = current_skin_hands1
			pony_avatar.scale = base_avatar_scale

func _input(event: InputEvent) -> void:
	# 1. 退出通道
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	# 2. 核心监听: 检测是否键盘的敲击时间，并且排除长按产生的连续触发 (echo)
	if event is InputEventKey and not event.is_echo():
		if event.is_pressed():
			# 只有过了视觉保护期，才允许翻转状态
			if visual_cooldown <= 0:
				is_hands1 = !is_hands1

				if is_hands1:
					pony_avatar.texture = current_skin_hands1
				else:
					pony_avatar.texture = current_skin_hands2
				
				# 重置视觉保护器，锁定当前状态
				visual_cooldown = min_visual_time

				# 计步器
				Config.total_hits += 1
				Config.save_game()
				hit_counter.text = str(Config.total_hits)
				if menu_panel.visible:
					refresh_menu()

				# 奖励检查
				check_unlocks()

			# 每次敲击都要重置 idle 倒计时
			idle_timer = idle_delay
			
			# 在 base_avatar_scale 的基础上做出挤压和形变
			var squash_y = randf_range(0.92, 0.96)
			pony_avatar.scale = Vector2(base_avatar_scale.x, base_avatar_scale.y * squash_y)


#【解锁判定函数】
func check_unlocks() -> void:
	# 当前的敲击次数在配置表里
	for need_hits in Config.unlock_config.keys():
		if Config.total_hits < need_hits:
			continue
		var reward_data = Config.unlock_config[need_hits]
		if Config.claimed_rewards.has(reward_data.id):
			continue
		pending_reward_data = reward_data

		item_icon.texture = load(reward_data.icon)
		unlock_bubble.visible = true
		unlock_bubble.pivot_offset = unlock_bubble.size / 2.0

		unlock_bubble.scale = Vector2(0.1, 0.1)
		var tween := create_tween()
		tween.tween_property(unlock_bubble, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BOUNCE)
		print("达成目标: ", need_hits, "次！")
		print("获得奖励: ", reward_data.get("reward_type"), reward_data.get("name"))
		print("-----------------------")

		return
	
#【气泡点击逻辑】
func _on_unlock_bubble_pressed() -> void:
	if pending_reward_data == null: return

	# 1. 标记为已领取，存入数组
	Config.claimed_rewards.append(pending_reward_data.id)
	Config.unlocked_skins.append(pending_reward_data.id)
	# 切换领取的皮肤ID，并实装
	Config.current_skin_id = pending_reward_data.id
	change_skin(Config.current_skin_id)
	Config.save_game()

	# 2. 隐藏气泡
	unlock_bubble.visible = false

	# 3. 展现浮窗
	hint_label.text = pending_reward_data.name + "已解锁!"
	float_hint.visible = true
	# float_hint.position.y = unlock_bubble.position.y - 50
	float_hint.modulate.a = 1.0

	# 4. 浮窗变透明
	var tween = create_tween()
	tween.tween_interval(1.0) # 等待 1 秒
	tween.tween_property(float_hint, "modulate:a", 0.0, 1.0)
	# a - 透明度
	# 0.0 最终数值
	# 1.0 1秒
	tween.tween_callback(func(): float_hint.visible = false) # 动画结束后隐藏

	pending_reward_data = null

func _on_menu_btn_pressed() -> void:
	menu_panel.visible = not menu_panel.visible
	if menu_panel.visible:
		refresh_menu()

func refresh_menu() -> void:
	menu_hits_label.text = "敲击次数：" + str(Config.total_hits)

func _on_skin_switch_btn_pressed() -> void:
	var skin_count = Config.unlocked_skins.size()
	if skin_count <= 0:
		return
	var current_index = Config.unlocked_skins.find(Config.current_skin_id)
	if current_index == -1:
		current_index = 0
	var next_index = current_index + 1
	if next_index >= skin_count:
		next_index = 0
	
	Config.current_skin_id = Config.unlocked_skins[next_index]
	change_skin(Config.current_skin_id)
	Config.save_game()
	refresh_menu()
