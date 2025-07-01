extends Node2D
var ClickParticle = preload("res://click_particle.tscn")

# REMOVE these now!
# var materials = { ... }
# var owned_units = { ... }

var producers = {
	"Grave": {
		"materials": ["meat", "bone"],
		"base_gains": {"meat": 1, "bone": 0.25},
	}
}

@onready var parts_tree = $CanvasLayer/PartsTree
@onready var unit_tree = $CanvasLayer/UnitTree

var parts_root = null
var units_root = null

func _ready():
	randomize()
	parts_root = parts_tree.create_item()
	parts_root.set_text(0, "Parts")
	parts_root.set_selectable(0, false)

	units_root = unit_tree.create_item()
	units_root.set_text(0, "Units")
	units_root.set_selectable(0, false)

	# Initialize tree items to null
	for mat_name in PlayerData.materials.keys():
		PlayerData.materials[mat_name]["tree_item"] = null
	for unit_name in PlayerData.owned_units.keys():
		PlayerData.owned_units[unit_name+"_tree_item"] = null

	var grave_button = $CanvasLayer/Grave
	grave_button.connect("pressed", Callable(self, "_on_Grave_pressed"))

func get_actual_gain(base_gain: float) -> int:
	var guaranteed = int(base_gain)
	var chance = base_gain - guaranteed
	return guaranteed + int(randf() < chance)

func _on_Grave_pressed():
	var grave = producers["Grave"]
	for mat_name in grave["materials"]:
		var base_gain = grave["base_gains"][mat_name] * PlayerData.materials[mat_name]["modifier"]
		var total_gain = get_actual_gain(base_gain)
		PlayerData.materials[mat_name]["amount"] += total_gain
		_check_and_discover_resource(mat_name)

# PARTS TREE
func _check_and_discover_resource(mat_name: String):
	var mat = PlayerData.materials[mat_name]
	if not mat["tree_item"] and mat["amount"] > 0:
		mat["tree_item"] = _create_material_tree_item(mat_name, mat["amount"])
	elif mat["tree_item"]:
		_update_material_tree_item(mat["tree_item"], mat_name, mat["amount"])

func _create_material_tree_item(mat_name: String, amount: int) -> TreeItem:
	var item = parts_tree.create_item(parts_root)
	item.set_text(0, "%s: %d" % [mat_name.capitalize(), amount])
	return item

func _update_material_tree_item(item: TreeItem, mat_name: String, amount: int) -> void:
	if item:
		item.set_text(0, "%s: %d" % [mat_name.capitalize(), amount])

# UNIT TREE
func increment_unit(unit_name: String):
	if not PlayerData.owned_units.has(unit_name):
		push_error("Tried to increment unknown unit %s" % unit_name)
		return
	PlayerData.owned_units[unit_name] += 1
	_check_and_discover_unit(unit_name)

	# Update ALL material displays after unit creation (or cost deduction)
	for mat_name in PlayerData.materials.keys():
		_check_and_discover_resource(mat_name)


func _check_and_discover_unit(unit_name: String):
	var key = unit_name+"_tree_item"
	if not PlayerData.owned_units.has(key):
		PlayerData.owned_units[key] = null
	if not PlayerData.owned_units[key] and PlayerData.owned_units[unit_name] > 0:
		PlayerData.owned_units[key] = _create_unit_tree_item(unit_name, PlayerData.owned_units[unit_name])
	elif PlayerData.owned_units[key]:
		_update_unit_tree_item(PlayerData.owned_units[key], unit_name, PlayerData.owned_units[unit_name])

func _create_unit_tree_item(unit_name: String, amount: int) -> TreeItem:
	var item = unit_tree.create_item(units_root)
	item.set_text(0, "%s: %d" % [unit_name, amount])
	return item

func _update_unit_tree_item(item: TreeItem, unit_name: String, amount: int) -> void:
	if item:
		item.set_text(0, "%s: %d" % [unit_name, amount])

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var Particles = ClickParticle.instantiate()
		get_tree().current_scene.get_node("CanvasLayer").add_child(Particles)
		Particles.restart()
		Particles.global_position = get_viewport().get_mouse_position()
