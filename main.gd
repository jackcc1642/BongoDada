extends Control

# 当检测到玩家输入时触发
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

# 首次git