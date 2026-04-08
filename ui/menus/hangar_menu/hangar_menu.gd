extends Menu
class_name HangarMenu

@onready var slots_grid: GridContainer = %SlotsGrid
@onready var type_label: Label = %TypeLabel
@onready var component_list: VBoxContainer = %ComponentList
@onready var left_arrow_button: Button = %LeftArrowButton
@onready var right_arrow_button: Button = %RightArrowButton
@onready var selected_label: Label = %SelectedLabel

@export var slot_names_base: Array[String] = [
	"engine_l", "engine_r", "power", "tractor", "weapon_1",
	"weapon_2", "weapon_3", "weapon_4", "rocket_1", "rocket_2",
	"shield"
]

enum Phase { BROWSE, PLACE }

var phase: Phase = Phase.BROWSE
var cursor_index: int = 0
var list_cursor_index: int = 0
var slot_panels: Array[Panel] = []
var slot_names: Array[String] = []

var current_type_index: int = 0
var component_type_list: Array[ComponentType.Type] = []
var selected_component: BaseComponent = null
var component_item_panels: Array[Panel] = []
var filtered_inventory: Array[BaseComponent] = []

const TOTAL_SLOTS: int = 20
const SLOT_COLUMNS: int = 5

func _ready() -> void:
	super._ready()
	setup_ui()
	component_type_list = ComponentType.get_all_types()

func show_menu() -> void:
	super.show_menu()
	phase = Phase.BROWSE
	cursor_index = 0
	list_cursor_index = 0
	selected_component = null
	current_type_index = 0
	update_type_display()
	refresh_slot_display()
	update_selected_label()

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

func _process(_delta: float) -> void:
	handle_input()

func handle_input() -> void:
	if phase == Phase.BROWSE:
		if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
			cycle_type(-1)
		elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
			cycle_type(1)
		elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
			move_list_cursor(-1)
		elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
			move_list_cursor(1)
		elif Input.is_action_just_pressed("fire_primary"):
			enter_place_phase()
	else:
		if Input.is_action_just_pressed("move_left"):
			move_cursor(-1)
		elif Input.is_action_just_pressed("move_right"):
			move_cursor(1)
		elif Input.is_action_just_pressed("move_up"):
			move_cursor_row(-1)
		elif Input.is_action_just_pressed("move_down"):
			move_cursor_row(1)
		elif Input.is_action_just_pressed("fire_primary"):
			place_component()
		elif Input.is_action_just_pressed("fire_secondary"):
			enter_browse_phase()

# --- Type cycling ---

func cycle_type(direction: int) -> void:
	current_type_index = (current_type_index + direction + component_type_list.size()) % component_type_list.size()
	list_cursor_index = 0
	update_type_display()

func update_type_display() -> void:
	type_label.text = ComponentType.type_to_string(component_type_list[current_type_index])
	refresh_component_list()

# --- Component list (right panel) ---

func refresh_component_list() -> void:
	for panel in component_item_panels:
		panel.queue_free()
	component_item_panels.clear()
	filtered_inventory.clear()

	if data == null:
		return

	var type_prefix: String = ComponentType.type_to_slot_prefix(component_type_list[current_type_index])
	for comp in data.component_inventory:
		if comp and comp.component_type == type_prefix:
			filtered_inventory.append(comp)

	for i in filtered_inventory.size():
		var comp: BaseComponent = filtered_inventory[i]

		var item_panel = Panel.new()
		item_panel.custom_minimum_size = Vector2(0, 32)

		var hbox = HBoxContainer.new()
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var swatch = ColorRect.new()
		swatch.color = comp.icon_color
		swatch.custom_minimum_size = Vector2(20, 20)
		hbox.add_child(swatch)

		var lbl = Label.new()
		lbl.text = comp.name if comp.name != "" else type_prefix
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		item_panel.add_child(hbox)
		component_list.add_child(item_panel)
		component_item_panels.append(item_panel)

	list_cursor_index = clampi(list_cursor_index, 0, maxi(0, filtered_inventory.size() - 1))
	update_list_display()

func move_list_cursor(delta: int) -> void:
	if filtered_inventory.is_empty():
		return
	list_cursor_index = (list_cursor_index + delta + filtered_inventory.size()) % filtered_inventory.size()
	update_list_display()

func update_list_display() -> void:
	for i in component_item_panels.size():
		component_item_panels[i].modulate = Color(1, 1, 0.4) if i == list_cursor_index else Color.WHITE

# --- Phase transitions ---

func enter_place_phase() -> void:
	if filtered_inventory.is_empty():
		return
	selected_component = filtered_inventory[list_cursor_index]
	phase = Phase.PLACE
	update_selected_label()
	refresh_slot_display()

func enter_browse_phase() -> void:
	selected_component = null
	phase = Phase.BROWSE
	update_selected_label()
	refresh_slot_display()
	update_list_display()

# --- Grid cursor (place phase) ---

func move_cursor(delta: int) -> void:
	cursor_index = (cursor_index + delta + TOTAL_SLOTS) % TOTAL_SLOTS
	refresh_slot_display()

func move_cursor_row(delta: int) -> void:
	var col: int = cursor_index % SLOT_COLUMNS
	@warning_ignore("integer_division")
	var row: int = cursor_index / SLOT_COLUMNS
	row = (row + delta + 4) % 4
	cursor_index = row * SLOT_COLUMNS + col
	refresh_slot_display()

func place_component() -> void:
	if data == null or selected_component == null:
		return
	var slot = slot_names[cursor_index]
	if slot == "":
		return
	var slot_prefix = slot.split("_")[0]
	if selected_component.component_type != slot_prefix:
		return

	# Swap old component back to inventory if present
	if data.ship_config.has(slot) and data.ship_config[slot] != null:
		data.component_inventory.append(data.ship_config[slot])

	data.component_inventory.erase(selected_component)
	data.ship_config[slot] = selected_component

	enter_browse_phase()
	refresh_component_list()

# --- Slot visuals ---

func refresh_slot_display() -> void:
	for i in TOTAL_SLOTS:
		var panel = slot_panels[i]
		var slot = slot_names[i]
		var color_rect = panel.get_child(0) as ColorRect

		if slot != "" and data != null and data.ship_config.has(slot):
			color_rect.color = data.ship_config[slot].icon_color
		elif slot != "":
			color_rect.color = Color(0.3, 0.3, 0.3)
		else:
			color_rect.color = Color(0.1, 0.1, 0.1)

		panel.modulate = Color.WHITE

	# Ghost preview at cursor in place phase
	if phase == Phase.PLACE and selected_component != null:
		var panel = slot_panels[cursor_index]
		var color_rect = panel.get_child(0) as ColorRect
		color_rect.color = selected_component.icon_color
		panel.modulate = Color(1.0, 1.0, 1.0, 0.55)

func update_selected_label() -> void:
	if selected_component == null:
		selected_label.text = "[Q] Pick component"
	else:
		selected_label.text = "Placing: %s  [W] Cancel" % selected_component.name

func _on_left_arrow_pressed() -> void:
	cycle_type(-1)

func _on_right_arrow_pressed() -> void:
	cycle_type(1)
