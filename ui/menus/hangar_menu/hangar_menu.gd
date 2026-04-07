extends Menu
class_name HangarMenu

@onready var slots_grid: GridContainer = %SlotsGrid
@onready var type_label: Label = %TypeLabel
@onready var component_list: VBoxContainer = %ComponentList
@onready var left_arrow_button: Button = %LeftArrowButton
@onready var right_arrow_button: Button = %RightArrowButton

@export var slot_names_base: Array[String] = [
	"engine_l", "engine_r", "power", "tractor", "weapon_1",
	"weapon_2", "weapon_3", "weapon_4", "rocket_1", "rocket_2",
	"shield"
]

var cursor_index: int = 0
var slot_panels: Array[Panel] = []
var slot_names: Array[String] = []

var current_type_index: int = 0
var component_type_list: Array[ComponentType.Type] = []
var selected_component: BaseComponent = null
var component_item_panels: Array[Panel] = []

const TOTAL_SLOTS: int = 20
const SLOT_COLUMNS: int = 5

func _ready() -> void:
	super._ready()
	setup_ui()
	component_type_list = ComponentType.get_all_types()

func show_menu() -> void:
	super.show_menu()
	setup_menu()
	load_config()
	current_type_index = 0
	update_type_display()

func setup_ui() -> void:
	for i in TOTAL_SLOTS:
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(80, 80)
		var color_rect = ColorRect.new()
		color_rect.color = Color.GRAY
		color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		color_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(color_rect)
		slots_grid.add_child(panel)
		slot_panels.append(panel)

	slot_names.resize(TOTAL_SLOTS)
	for i in slot_names_base.size():
		slot_names[i] = slot_names_base[i]

	update_cursor()

func load_config() -> void:
	if data == null:
		return
	for i in TOTAL_SLOTS:
		var slot = slot_names[i]
		if slot != "" and data.ship_config.has(slot):
			var comp: BaseComponent = data.ship_config[slot]
			slot_panels[i].get_child(0).color = comp.icon_color
		elif slot != "":
			slot_panels[i].get_child(0).color = Color.GRAY

func save_config() -> void:
	# Later JSON save
	pass

func _process(_delta: float) -> void:
	handle_input()

func handle_input() -> void:
	if Input.is_action_just_pressed("ui_left"):
		cycle_type(-1)
	elif Input.is_action_just_pressed("ui_right"):
		cycle_type(1)
	elif Input.is_action_just_pressed("move_left"):
		move_cursor(-1)
	elif Input.is_action_just_pressed("move_right"):
		move_cursor(1)
	elif Input.is_action_just_pressed("move_up"):
		move_cursor_up()
	elif Input.is_action_just_pressed("move_down"):
		move_cursor_down()
	elif Input.is_action_just_pressed("ui_accept"):
		handle_accept()
	elif Input.is_action_just_pressed("ui_cancel"):
		handle_cancel()

func cycle_type(direction: int) -> void:
	current_type_index = (current_type_index + direction + component_type_list.size()) % component_type_list.size()
	update_type_display()

func update_type_display() -> void:
	var current_type: ComponentType.Type = component_type_list[current_type_index]
	type_label.text = ComponentType.type_to_string(current_type)
	refresh_component_list()

func refresh_component_list() -> void:
	for panel in component_item_panels:
		panel.queue_free()
	component_item_panels.clear()

	if data == null:
		return

	var current_type: ComponentType.Type = component_type_list[current_type_index]
	var type_prefix: String = ComponentType.type_to_slot_prefix(current_type)

	for slot_name in data.ship_config:
		var comp: BaseComponent = data.ship_config[slot_name]
		if comp and comp.component_type == type_prefix:
			var item_panel = Panel.new()
			item_panel.custom_minimum_size = Vector2(0, 30)

			var hbox = HBoxContainer.new()
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var color_rect = ColorRect.new()
			color_rect.color = comp.icon_color
			color_rect.custom_minimum_size = Vector2(20, 20)
			hbox.add_child(color_rect)

			var label = Label.new()
			label.text = comp.name if comp.name else type_prefix
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(label)

			item_panel.add_child(hbox)
			component_list.add_child(item_panel)
			component_item_panels.append(item_panel)

func move_cursor(delta: int) -> void:
	cursor_index = (cursor_index + delta + TOTAL_SLOTS) % TOTAL_SLOTS
	update_cursor()

func move_cursor_up() -> void:
	var col: int = cursor_index % SLOT_COLUMNS
	@warning_ignore("integer_division")
	var row: int = cursor_index / SLOT_COLUMNS
	row = (row - 1 + 4) % 4
	cursor_index = row * SLOT_COLUMNS + col
	update_cursor()

func move_cursor_down() -> void:
	var col: int = cursor_index % SLOT_COLUMNS
	@warning_ignore("integer_division")
	var row: int = cursor_index / SLOT_COLUMNS
	row = (row + 1) % 4
	cursor_index = row * SLOT_COLUMNS + col
	update_cursor()

func handle_accept() -> void:
	handle_slot_accept()

func handle_slot_accept() -> void:
	if data == null: return
	var slot = slot_names[cursor_index]
	if slot == "": return
	if selected_component == null: return
	var slot_prefix = slot.split("_")[0]
	if selected_component.component_type != slot_prefix: return
	data.ship_config[slot] = selected_component.duplicate()
	slot_panels[cursor_index].get_child(0).color = selected_component.icon_color
	print("Placed ", selected_component.component_type, " in ", slot)

func handle_cancel() -> void:
	handle_slot_cancel()

func handle_slot_cancel() -> void:
	if data == null: return
	var slot = slot_names[cursor_index]
	if slot == "": return
	if data.ship_config.has(slot):
		data.ship_config.erase(slot)
		slot_panels[cursor_index].get_child(0).color = Color.GRAY
		refresh_component_list()
		print("Removed from ", slot)

func update_cursor() -> void:
	for panel in slot_panels:
		panel.modulate = Color.WHITE
	if cursor_index < TOTAL_SLOTS:
		slot_panels[cursor_index].modulate = Color(1, 1, 0.5)

func _on_left_arrow_pressed() -> void:
	cycle_type(-1)

func _on_right_arrow_pressed() -> void:
	cycle_type(1)
