extends Control

onready var control_tab = get_node("ControlTab")
onready var control = get_node("Control")
onready var dialog = get_node("Dialog")
onready var menu = get_node("Menu")
onready var inventory = get_node("Inventory")
onready var trade = get_node("Trade")
var visible_node

func _ready():
	get_node("ControlTab/Label").set_text(tr("CONTROLLS"))
	get_node("Control/Label").set_text(tr("MENU"))
	get_node("Control/Label2").set_text(tr("INTERACTION"))
	get_node("Control/Label3").set_text(tr("INVENTORY"))
	get_node("Control/Label4").set_text(tr("RUN"))
	get_node("Control/Label6").set_text(tr("MOVEMENT"))
	get_node("Control/Panel6/Label").set_text(tr("MOUSE"))
	get_node("Dialog/Label2").set_text(tr("INTERACTION"))
	get_node("Inventory/Label3").set_text(tr("CLOSE"))
	get_node("Inventory/Label4").set_text(tr("SPLITITEMS"))
	get_node("Trade/Label2").set_text(tr("CLOSE"))
	get_node("Trade/Label4").set_text(tr("SPLITITEMS"))
	get_node("Menu/Label2").set_text(tr("CLOSEMENU"))

# makes all control notes invisible
func hide():
	if control_tab.visible:
		visible_node = control_tab
	else:
		visible_node = control
	control_tab.visible = false
	control.visible = false
	dialog.visible = false
	menu.visible = false
	inventory.visible = false
	trade.visible = false

# shows the control notes
func show():
	visible_node.visible = true

# control notes toggle with tab
func show_hide_control_notes():
	if !control_tab.visible and !dialog.visible and !menu.visible and !inventory.visible and !trade.visible and !control.visible:
		pass
	elif control_tab.visible:
		if Utils.get_scene_manager().get_node("UI").get_node_or_null("GameMenu") != null:
			menu.visible = true
		elif Utils.get_scene_manager().get_node("UI").get_node_or_null("CharacterInterface") != null:
			inventory.visible = true
		elif Utils.get_scene_manager().get_node("UI").get_node_or_null("TradeInventory") != null:
			trade.visible = true
		else:
			control.visible = true
		control_tab.visible = false
	else:
		control_tab.visible = true
		control.visible = false
		dialog.visible = false
		menu.visible = false
		inventory.visible = false
		trade.visible = false

# change the control notes by interactions
func update():
	if !control_tab.visible and !dialog.visible and !menu.visible and !inventory.visible and !trade.visible and !control.visible:
		pass
	elif !control_tab.visible:
		control.visible = false
		dialog.visible = false
		menu.visible = false
		inventory.visible = false
		trade.visible = false
		if Utils.get_scene_manager().get_node("UI").get_node_or_null("GameMenu") != null:
			menu.visible = true
		elif Utils.get_scene_manager().get_node("UI").get_node_or_null("CharacterInterface") != null:
			inventory.visible = true
		elif Utils.get_scene_manager().get_node("UI").get_node_or_null("TradeInventory") != null:
			trade.visible = true
		else:
			control.visible = true

# changes the control notes when enter/exit world
func in_world(value):
	if value:
		control_tab.visible = true
		control.visible = false
		dialog.visible = false
		menu.visible = false
		inventory.visible = false
		trade.visible = false
	else:
		control_tab.visible = false
		control.visible = false
		dialog.visible = false
		menu.visible = false
		inventory.visible = false
		trade.visible = false