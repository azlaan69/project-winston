extends BaseEnemy

func _physics_process(delta: float) -> void:
	super(delta)

func hit(hit_data: Dictionary) -> void:
	if iframe_timer > 0.0: return
	if hit_data["damage"] < 10.0:
		pass
		return
	hp -= hit_data["damage"]
	iframe_timer = 0.05
