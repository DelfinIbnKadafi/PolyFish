extends KinematicBody

export var gravitation: float = 20.0
export var sensivity: float = 0.01
export var speed: float = 5.0
export var jump_force: float = 8.0

var velocity = Vector3.ZERO
var fishing_rotation_y = rotation.y
var fishing_rotation_x = rotation.x

onready var head = $head

var mouse: bool = false
var size_screen_x = 0
var size_screen_y = 0
onready var cursor = get_parent().get_node("cursor/ColorRect")

var start_game = false
var status_fishing = false

onready var cam1 = get_parent().get_node("main_menu_camera")
onready var cam2 = get_parent().get_node("player/head/Camera")

var touchFrom = "mouse"

var didplayerwasclickclosefishget = false
var didplayergetfish = false

var fishData = {}

func _ready():
	update_screen_size()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_parent().get_node("main_menu_camera").current = true
	get_parent().get_node("pause/exit").visible = false
	get_parent().get_node("pause/judul").visible = false
	get_parent().get_node("pause/resume").visible = false
	start_game = false
	cursor.visible = false
	$head/fishingrod.visible = false
	randomize()



func pause():
	$"../footsteps".stop()
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse = true
		velocity.y = 0
		get_parent().get_node("pause/exit").visible = true
		get_parent().get_node("pause/judul").visible = true
		get_parent().get_node("pause/resume").visible = true
		get_parent().get_node("pause/setting_pause").visible = true
		get_parent().get_node("gameUI").visible = false
		get_parent().get_node("cursor").visible = false
		if OS.get_name() == "Android":
			get_parent().get_node("gameUI/item").visible = false
			get_parent().get_node("joystick").visible = false
			get_parent().get_node("mobileButton").visible = false
			get_parent().get_node("pause_button").visible = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse = false
		get_parent().get_node("pause/judul").visible = false
		get_parent().get_node("pause/exit").visible = false
		get_parent().get_node("pause/resume").visible = false
		get_parent().get_node("pause/setting_pause").visible = false
		get_parent().get_node("gameUI").visible = true
		get_parent().get_node("cursor").visible = true
		if OS.get_name() == "Android":
			get_parent().get_node("gameUI/item").visible = false
			get_parent().get_node("joystick").visible = true
			get_parent().get_node("mobileButton").visible = true
			get_parent().get_node("pause_button").visible = true


func fishing():
	var common = {
		"Sardine": 50,
		"Mackerel": 50
	}
	var uncommon = {
		"Dorado": 40,
		"Barracuda": 30,
		"Red Snapper": 20,
		"Yellowfin Tuna": 10
	}
	var rare = {
		"Blue Marlin": 40,
		"Sail Fish": 30,
		"Hammerhad Shark": 20,
		"Great White SHark": 10
	}
	
	var chance = randf() * 100
	
	if chance <= 55:
		chance = randf() * 100
		var total = 0
		for fish in common:
			total += common[fish]
			if chance <= total:
				return {
					"fish": fish,
					"rarity": "Common"
				}
	elif chance <= 85:
		chance = randf() * 100
		var total = 0
		for fish in uncommon:
			total += uncommon[fish]
			if chance <= total:
				return {
					"fish": fish,
					"rarity": "Uncommon"
				}
	else:
		chance = randf() * 100
		var total = 0
		for fish in rare:
			total += rare[fish]
			if chance <= total:
				return {
					"fish": fish,
					"rarity": "Rare"
				}


func saveFishData():
	var file = File.new()
	file.open("user://fish_data.json", File.WRITE)
	file.store_string(to_json(fishData))
	file.close()
	return true


func storeFish(fishName: String, rarity: String):
	var file = File.new()

	# if the file is exist, take the data from the file and store it on fishData
	if file.file_exists("user://fish_data.json"):
		file.open("user://fish_data.json", File.READ)
		fishData = parse_json(file.get_as_text())
		file.close()
	
	fishData[fishName] = {
		"Count": fishData[fishName]["Count"] + 1 if fishData.has(fishName) else 1,
		"Rarity": rarity
	}
	# so the fish_data.json will be like this
	"""
	{
		"Sardine": {
			"Count": 1,
			"Rarity": "Common"
		},
		"Mackerel": {
			"Count": 2,
			"Rarity": "Common"
		}
	}
	"""
	saveFishData()
	return true


# i should to make the function, when if player throw a fishing rod, player need to wait for a few times (i need create a rondom pick time for 10-30 seconds) and if timer was end, player cant catch the fishing rod and get the fish using func fishing()
var didplayerlostthefish = false

func interractFishingRod():
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or didplayerwasclickclosefishget:
		return
	if not $head/fishingrod.visible:
		return
	$"../footsteps".stop()

	if status_fishing:
		if not didplayergetfish:
			return
		didplayergetfish = false
		get_parent().get_node("catchnow").visible = false
		$head/fishingrod/AnimationPlayer.play("tarik")
		var hasil = fishing()
		get_parent().get_node("fishget").visible = true
		var fishname = get_parent().get_node("fishget/fishname")
		var font = DynamicFont.new()
		font.font_data = load("res://assets/fonts/Roboto_Condensed-Bold.ttf")
		font.size = 16
		fishname.add_font_override("bold_font", font)
		fishname.bbcode_text = "[b]" + hasil["fish"] + "[/b]"
		var fonts = DynamicFont.new()
		fonts.font_data = load("res://assets/fonts/Inter_18pt-Bold.ttf")
		fonts.size = 33
		var label = get_parent().get_node("fishget/type")
		label.add_font_override("bold_font", fonts)
		label.bbcode_text = "[b]" + hasil["rarity"] + "[/b]"
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse = true
		cursor.visible = false
		status_fishing = false
		didplayerlostthefish = false
		var camera = $head/Camera
		var object = get_parent().get_node("fishing_bobber")
		var target = camera.global_transform.origin - camera.global_transform.basis.z * 50.0
		object.global_transform.origin = Vector3(target.x, 0.8, target.z)
		var tween = Tween.new()
		add_child(tween)
		tween.interpolate_property(object, "global_transform:origin", object.global_transform.origin, Vector3(target.x, 50.0, target.z), 1.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween.start()
		yield(get_tree().create_timer(1.0), "timeout")
		object.visible = false
		# store the fish on data
		storeFish(hasil["fish"], hasil["rarity"])
		return

	$head/fishingrod/AnimationPlayer.play("throw")
	status_fishing = true
	didplayerlostthefish = false
	didplayergetfish = false
	fishing_rotation_y = rotation.y
	fishing_rotation_x = rotation.x
	var camera = $head/Camera
	var object = get_parent().get_node("fishing_bobber")
	var distance = 50.0
	var forward = -camera.global_transform.basis.z
	var target = camera.global_transform.origin + forward * distance
	object.global_transform.origin = Vector3(target.x, 50.0, target.z)
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(object, "global_transform:origin", object.global_transform.origin, Vector3(target.x, 0.8, target.z), 1.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	object.visible = true
	tween.start()

	yield(get_tree().create_timer(rand_range(10.0, 30.0)), "timeout")
	if not status_fishing:
		return
	didplayergetfish = true
	get_parent().get_node("catchnow").visible = true
	yield(get_tree().create_timer(5.0), "timeout")
	if not didplayergetfish or not status_fishing:
		return
	didplayergetfish = false
	didplayerlostthefish = true
	get_parent().get_node("catchnow").visible = false
	$head/fishingrod/AnimationPlayer.play("tarik")
	status_fishing = false
	object.visible = false


func _physics_process(delta):
	if start_game == false:
		if Input.is_action_just_pressed("space") and get_parent().get_node("setting").visible == false:
			get_parent().get_node("mainMenu").visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			update_screen_size()
			CameraTransition.transition_camera3D(cam1, cam2, 4.0)
			yield(get_tree().create_timer(2.0), "timeout")
			get_parent().get_node("character").visible = false
			yield(get_tree().create_timer(1.0), "timeout")
			$head/hand/AnimationPlayer.play("open")
			$head/hand.visible = true
			yield(get_tree().create_timer(1.0), "timeout")
			cursor.visible = true
			get_parent().get_node("gameUI").visible = true
			get_parent().get_node("gameUI/item").rect_position.x = get_viewport().size.x - 100
			get_parent().get_node("gameUI/item").rect_position.y = get_viewport().size.y - 50
			if OS.get_name() == "Android":
				get_parent().get_node("joystick").visible = true
				get_parent().get_node("gameUI/item").visible = false
				get_parent().get_node("mobileButton").visible = true
				get_parent().get_node("pause_button").visible = true
			start_game = true
	if start_game == true:
		if get_viewport().size.x != size_screen_x or get_viewport().size.y != size_screen_y:
			update_screen_size()
		# gravitation
		gravity(delta)
		
		# movement
		var direction = Vector3.ZERO
		if mouse == false:
			if Input.is_action_just_pressed("left") and touchFrom == "mouse":
				interractFishingRod()
			if Input.is_action_just_pressed("0"):
				if status_fishing == false and $head/hand.visible == false:
					$head/fishingrod/AnimationPlayer.play("close")
					yield(get_tree().create_timer(0.3), "timeout")
					$head/fishingrod.visible = false
					$head/hand/AnimationPlayer.play("open")
					$head/hand.visible = true
			if Input.is_action_just_pressed("1"):
				if status_fishing == false:
					if $head/fishingrod.visible == true:
						$head/fishingrod/AnimationPlayer.play("close")
						yield(get_tree().create_timer(0.3), "timeout")
						$head/fishingrod.visible = false
						$head/hand/AnimationPlayer.play("open")
						$head/hand.visible = true
					else:
						$head/hand/AnimationPlayer.play("close")
						yield(get_tree().create_timer(0.3), "timeout")
						$head/hand.visible = false
						$head/fishingrod/AnimationPlayer.play("open")
						$head/fishingrod.visible = true
			var moving = false
			if status_fishing == false:
				if Input.is_action_pressed("w"):
					direction -= transform.basis.z
					moving = true
				if Input.is_action_pressed("s"):
					direction += transform.basis.z
					moving = true
				if Input.is_action_pressed("a"):
					direction -= transform.basis.x
					moving = true
				if Input.is_action_pressed("d"):
					direction += transform.basis.x
					moving = true
				if moving:
					if !$"../footsteps".playing:
						$"../footsteps".play()
				else:
					$"../footsteps".stop()
				if is_on_floor():
					velocity.y = 0
					if Input.is_action_just_pressed("space"):
						velocity.y = jump_force
						$"../footsteps".stop()
					
		# esc mouse
		if Input.is_action_just_pressed("esc"):
			pause()
		
		# change pos
		direction.y = 0
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		velocity = move_and_slide(velocity, Vector3.UP)


func _input(event):
	if start_game == true:
		if mouse == false:
			if event is InputEventMouseMotion:
				if event.position.x > 300:
					rotate_y(-event.relative.x * sensivity)
					head.rotate_x(-event.relative.y * sensivity)
					head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
					if status_fishing == true:
						rotation.y = clamp(rotation.y, fishing_rotation_y - deg2rad(30), fishing_rotation_y + deg2rad(30))
			if event is InputEventScreenDrag:
				if event.position.x > 300:
					rotate_y(-event.relative.x * sensivity)
					head.rotate_x(-event.relative.y * sensivity)
					head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
					if status_fishing:
						rotation.y = clamp(rotation.y, fishing_rotation_y - deg2rad(30), fishing_rotation_y + deg2rad(30))	
						
func gravity(delta):
	if mouse == false:
		velocity.y -= gravitation * delta


func update_screen_size():
	size_screen_x = get_viewport().size.x
	size_screen_y = get_viewport().size.y
	
	cursor.rect_position.x = (size_screen_x - cursor.rect_size.x) / 2
	cursor.rect_position.y = (size_screen_y - cursor.rect_size.y) / 2

func _on_resume_pressed():
	pause()


func _on_play_pressed():
	Input.action_press("space")


func _on_offhand_pressed():
	Input.action_press("0")
	touchFrom = "touchscreen"


func _on_fishrod_pressed():
	if get_parent().get_node("player/head/fishingrod").visible == false:
		touchFrom = "touchscreen"
		Input.action_press("1")
	else:
		Input.action_press("left")


func _on_jump_pressed():
	touchFrom = "touchscreen"
	Input.action_press("space")


func _on_pause_pressed():
	pause()


func _on_ok_pressed():
	get_parent().get_node("fishget").visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse = false
	cursor.visible = true
	didplayerwasclickclosefishget = true
	yield(get_tree().create_timer(1), "timeout")
	didplayerwasclickclosefishget = false
