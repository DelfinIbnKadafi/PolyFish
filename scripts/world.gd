extends Spatial

onready var timer = Timer.new()

onready var bg_sound = $background_sound

var settingData
var settingDatapath = "user://setting.json"

var watersetoption
var idsetwater = 1

func restart_bg_song():
	bg_sound.stop()
	bg_sound.play()

	if timer.get_parent() == null:
		add_child(timer)

	timer.wait_time = 233
	timer.one_shot = true

	if not timer.is_connected("timeout", self, "restart_bg_song"):
		timer.connect("timeout", self, "restart_bg_song")

	timer.start()

func savesetting():
	var file = File.new()
	
	file.open(settingDatapath, File.WRITE)
	
	file.store_string(to_json(settingData))
	file.close()
	settingData = loadsetting()
	return true

func loadsetting():
	var file = File.new()
	
	var defaultData = {
		"water": "medium",
		"autosave": 30,
		"sensivity": 70
	}
	
	if not file.file_exists(settingDatapath):
		file.open(settingDatapath, File.WRITE)
		file.store_string(to_json(defaultData))
		file.close()
	
	file.open(settingDatapath, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	
	for key in defaultData:
		if not data.has(key):
			data[key] = defaultData[key]
	
	var water_shader = Shader.new()
	
	if data["water"] == "low":
		water_shader.code = """
			shader_type spatial;

			uniform vec4 water_color : hint_color = vec4(0.039, 0.882, 0.992, 1.0);

			uniform float wave_height = 0.35;
			uniform float wave_size = 14.0;
			uniform float wave_speed = 0.6;

			varying float wave;

			void vertex() {
				float x = VERTEX.x;
				float z = VERTEX.z;

				wave = sin(x / wave_size + TIME * wave_speed);

				VERTEX.y += wave * wave_height;

				float dx = cos(x / wave_size + TIME * wave_speed) / wave_size;

				NORMAL = normalize(vec3(
					-dx * wave_height,
					1.0,
					0.0
				));
			}

			void fragment() {
				ALBEDO = water_color.rgb;

				ROUGHNESS = 0.45;
				SPECULAR = 0.5;
			}
		"""
		idsetwater = 0
	if data["water"] == "medium":
		water_shader.code = """
			shader_type spatial;

			uniform vec4 water_color : hint_color = vec4(0.039, 0.882, 0.992, 1.0);
			uniform vec4 foam_color : hint_color = vec4(1.0, 1.0, 1.0, 1.0);

			uniform float wave_height = 0.45;
			uniform float wave_size = 12.0;
			uniform float wave_speed = 0.65;

			varying float wave;

			void vertex() {
				float x = VERTEX.x;
				float z = VERTEX.z;

				float w1 = sin(x / wave_size + TIME * wave_speed);
				float w2 = cos(z / (wave_size * 1.3) + TIME * wave_speed * 0.7);

				wave = (w1 + w2) * 0.5;

				VERTEX.y += wave * wave_height;

				float dx = cos(x / wave_size + TIME * wave_speed) / wave_size;
				float dz = -sin(z / (wave_size * 1.3) + TIME * wave_speed * 0.7) / (wave_size * 1.3);

				NORMAL = normalize(vec3(
					-dx * wave_height * 0.5,
					1.0,
					-dz * wave_height * 0.5
				));
			}

			void fragment() {
				float foam = smoothstep(0.7, 0.9, abs(wave));

				ALBEDO = mix(water_color.rgb, foam_color.rgb, foam);

				ROUGHNESS = 0.4;
				SPECULAR = 0.65;
			}
		"""
		idsetwater = 1
	if data["water"] == "high":
		water_shader.code = """
			shader_type spatial;

			uniform vec4 water_color : hint_color = vec4(0.039, 0.882, 0.992, 1.0);
			uniform vec4 foam_color : hint_color = vec4(1.0, 1.0, 1.0, 1.0);

			uniform float wave_height = 0.5;
			uniform float wave_size = 5.0;
			uniform float wave_speed = 0.7;

			varying float wave;

			void vertex() {
				float x = VERTEX.x;
				float z = VERTEX.z;

				float w1 = sin(x / wave_size + TIME * wave_speed);
				float w2 = cos(z / (wave_size * 1.3) + TIME * wave_speed * 0.7);
				float w3 = sin((x + z) / (wave_size * 2.0) + TIME * 0.35);

				wave = (w1 + w2 + w3) / 3.0;

				VERTEX.y += wave * wave_height;

				float dx1 = cos(x / wave_size + TIME * wave_speed) / wave_size;
				float dz1 = 0.0;

				float dx2 = 0.0;
				float dz2 = -sin(z / (wave_size * 1.3) + TIME * wave_speed * 0.7) / (wave_size * 1.3);

				float dx3 = cos((x + z) / (wave_size * 2.0) + TIME * 0.35) / (wave_size * 2.0);
				float dz3 = dx3;

				float dx = (dx1 + dx2 + dx3) / 3.0;
				float dz = (dz1 + dz2 + dz3) / 3.0;

				NORMAL = normalize(vec3(
					-dx * wave_height,
					1.0,
					-dz * wave_height
				));
			}

			void fragment() {
				float foam = smoothstep(0.65, 0.9, abs(wave));

				ALBEDO = mix(water_color.rgb, foam_color.rgb, foam);

				ROUGHNESS = 0.35;
				SPECULAR = 0.8;
			}
		"""
		idsetwater = 2
		
	var material = ShaderMaterial.new()
	material.shader = water_shader
	$water.material_override = material
	
	return data

func autoSave():
	while true:
		savesetting()
		yield(get_tree().create_timer(settingData["autosave"]), "timeout")


func _ready():
	settingData = loadsetting()
	$catchnow.visible = false
	$fishing_bobber.visible = false
	$fishget.visible = false
	$setting/autosave/HSlider.value = settingData["autosave"]
	autoSave()
	$pause_button.visible = false
	$setting.visible = false
	restart_bg_song()
	$mainMenu/exit.rect_position.y = get_viewport().size.y - 70
	$mainMenu/setting.rect_position.y = get_viewport().size.y - 70
	$gameUI.visible = false
	$player/head/hand.visible = false
	$joystick.rect_position.y = get_viewport().size.y - 200
	$joystick.visible = false
	$mainMenu/play.visible = false
	$mobileButton.visible = false
	$mobileButton.rect_position.x = get_viewport().size.x - 200
	$mobileButton.rect_position.y = get_viewport().size.y - 200
	$pause/setting_pause.visible = false
	
	if OS.get_name() == "Android":
		$mainMenu/information.visible = false
		$mainMenu/play.visible = true
	
func _on_exit_pressed():
	get_tree().quit()


func _on_setting_pressed():
	loadsetting()
	$setting/water/option.select(idsetwater)
	$setting.visible = true
	$mainMenu.visible = false
	$setting/autosave/HSlider.value = settingData["autosave"]
	$setting/sensivity/HSlider.value = settingData["sensivity"]


func _on_cancel_pressed():
	if $main_menu_camera.current == true:
		$setting.visible = false
		$mainMenu.visible = true
	else:
		$setting.visible = false
		$pause.visible = true
	return


func _on_apply_pressed():
	if watersetoption != null:
		settingData["water"] = watersetoption
	settingData["autosave"] = $setting/autosave/HSlider.value
	settingData["sensivity"] = $setting/sensivity/HSlider.value
	$player.sensivity = 0.000142857 * settingData["sensivity"]
	savesetting()
	$setting.visible = false
	
	if $main_menu_camera.current == true:
		$mainMenu.visible = true
	else:
		$pause.visible = true
	return

func _on_setting_pause_pressed():
	loadsetting()
	$setting/water/option.select(idsetwater)
	$setting.visible = true
	$pause.visible = false
	$setting/autosave/HSlider.value = settingData["autosave"]
	$setting/sensivity/HSlider.value = settingData["sensivity"]
	

func _on_option_item_selected(index):
	match index:
		0:
			watersetoption = "low"
		1:
			watersetoption = "medium"
		2:
			watersetoption = "high"

func _process(delta):
	# how to fix unused delta?
	delta = delta
	if $setting.visible == true:
		$setting/autosave/HSlider/Label.text = str($setting/autosave/HSlider.value)
		$setting/sensivity/HSlider/Label.text = str($setting/sensivity/HSlider.value)
