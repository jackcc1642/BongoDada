extends Control

# 引用小马节点
@onready var pony_avatar: TextureRect = $PonyAvatar

#【皮肤纹理引用 - 为拓展做准备】
# 预加载防止切换时卡顿
# 如果后续增加新皮肤，只需要在此定义 xxx_hands1, xxx_hands2 即可
var pony_hands1 = preload("res://assets/images/pony_hands1.png")
var pony_hands2 = preload("res://assets/images/pony_hands2.png")

#【当前皮肤状态】
# 默认使用第一套皮肤
var current_skin_hands1 = pony_hands1
var current_skin_hands2 = pony_hands2


#【新增】记录当前是不是 hands1 状态
var is_hands1: bool = true
#【新增】停止敲击多长时间后，强制回到 IDLE 状态
var idle_timer: float = 0.0
## 0.15秒不敲键盘就回到 hands1
var idle_delay: float = 0.15 

#【新增】记录当前按住的按键数量--防止高速敲击键盘时小动物跟不上
var active_keys: int = 0


func _ready() -> void:
	# 游戏开始时的发呆状态
	pony_avatar.texture = current_skin_hands1
	# 把小马形变的中心点放在底部中间，这样下压的时候，底部会固定在屏幕边缘
	pony_avatar.pivot_offset = Vector2(pony_avatar.size.x / 2.0, pony_avatar.size.y)

func _process(delta: float) -> void:
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
			# 状态翻转，如果是 true 就变成 false，反之亦然
			is_hands1 = !is_hands1

			if is_hands1:
				pony_avatar.texture = pony_hands1
			else:
				pony_avatar.texture = pony_hands2

			# 每次敲击都要重置 idle 倒计时
			idle_timer = idle_delay
			pony_avatar.scale = Vector2(1.05, 0.9)
