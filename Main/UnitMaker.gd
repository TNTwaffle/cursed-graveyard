extends Control

var units = Unitlist.units

@onready var unit_list_vbox = $ScrollContainer/VBoxContainer

func _ready():
	_make_unit_buttons()

func _make_unit_buttons():
	for button in unit_list_vbox.get_children():
		button.queue_free() # Remove old buttons, if any
	for unit_name in units.keys():
		var data = units[unit_name]
		var reqs_str = ""
		for material in data["reqs"].keys():
			reqs_str += "%s: %d  \n" % [material, data["reqs"][material]]
		var btn = Button.new()
		btn.text = "%s (%s)" % [unit_name, reqs_str.substr(0, reqs_str.length() - 2)]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		unit_list_vbox.add_child(btn)
		btn.pressed.connect(func(): _on_unit_button_pressed(unit_name))


func _on_unit_button_pressed(unit_name):
	var unit_data = Unitlist.units[unit_name]
	var reqs = unit_data["reqs"]
	
	# 1. Check if player has enough for each required material
	for mat_name in reqs.keys():
		if not PlayerData.materials.has(mat_name) or PlayerData.materials[mat_name]["amount"] < reqs[mat_name]:
			print("Not enough %s to make %s" % [mat_name, unit_name])
			return # Exit, do nothing

	# 2. Deduct cost
	for mat_name in reqs.keys():
		PlayerData.materials[mat_name]["amount"] -= reqs[mat_name]

	# 3. Add unit
	get_tree().current_scene.increment_unit(unit_name)
