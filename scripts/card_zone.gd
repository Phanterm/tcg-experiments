@tool
extends Control

## CardZone enforces rules for which cards may or may not be placed within them.

class_name CardZone

## The preloaded slot instance used to generate new slots on the fly. 
var slot : PackedScene = preload("res://scenes/card_slot.tscn")

## The [Player] who owns this slot.
var player_owner : Player

## This node must point at the [Control] node that contains [CardSlot] as its immediate children.
@export var card_group : Control

## Determines how [CardSlot]s placed within this node's hierarchy are sorted and categorized.
@export var zone_type : GameBoard.Zones:
	set = set_zone_type

func set_zone_type(value):
	zone_type = value
	set_zone_size(zone_size)

## Determines how many cards exist within this zone. By default, deck, trash are forced to a size of [code]1[/code], and the hand has a size of [code]0[/code], indicating no limit.
@export_range(0, 24) var zone_size : int = 1:
	set = set_zone_size

func set_zone_size(value):
	if !is_node_ready(): return

	zone_size = value
	
	if zone_type == GameBoard.Zones.Deck || zone_type == GameBoard.Zones.Trash:
		zone_size = 1
	elif zone_type == GameBoard.Zones.Hand:
		zone_size = 0

	if Engine.is_editor_hint():
		if !card_group: return

		if card_group.get_child_count() > 0:
			for i in card_group.get_children():
				i.queue_free()
		for i in zone_size:
			var new_slot : CardSlot = slot.instantiate()
			new_slot.set_name("CardSlot")
			get_tree().edited_scene_root.get_node(card_group.get_path()).add_child(new_slot)
			new_slot.set_owner(get_tree().edited_scene_root)
			new_slot.slot_type = zone_type

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_gather_signals()
	if !Engine.is_editor_hint():
		_initialize_cards()

## This function assigns ownership to all children [CardSlot] nodes to the current [Player].
func _initialize_cards():
	player_owner = get_parent().owner
	for i in card_group.get_children():
		if i is CardSlot && i.get_card() && player_owner:
			var card = i.get_card()
			card.original_owner = player_owner
			card.current_owner = player_owner

func _gather_signals():
	card_group.child_order_changed.connect(_assign_slot_properties)

## This function is called whenever the children of this node's [member card_group] changes.
##
## For the hand, this function enforces z_indexing and calls [member order_hand] to provide a fanning effect.
func _assign_slot_properties():
	if card_group.get_child_count() > 0:
		if zone_type == GameBoard.Zones.Hand:
			var adj : int = 0
			for i in card_group.get_children():
				if i is CardSlot:
					i.z_index = 20
					i.z_index += adj
					adj += 1
			order_hand()
		else:
			for i in card_group.get_children():
				if i is CardSlot:
					i.slot_type = zone_type
					i.initialize_slot()

## This function sorts and orders [CardSlot]s in the hand area to become offset and rotated, creating a fanning effect.
func order_hand():
	if zone_type != GameBoard.Zones.Hand || card_group == null: return

	var cards = card_group.get_children()
	var count = cards.size()

	#TODO: If count > whatever value we want to be "max" for a fan, we can arrange it differently here.
	if count == 0:
		return
	
	var spacing = 80.0 #card_group.size.x         # total width of the fan
	var max_angle = 10.0       # degrees

	var center_index = (count - 1) / 2.0

	if count > 8:
		for i in range(count):
			var offset = i - center_index
			var card = cards[i]
			
			var x = offset * 48
			
			card.position.x = x
			card.position.y = 0
			card.rotation_degrees = 0
	else:
		
		for i in range(count):
			var offset = i - center_index  # now centered around 0

			var card = cards[i]

			# Horizontal spread
			var x = offset * spacing

			# Vertical curve (arc)
			var y = pow(offset / center_index if center_index != 0 else 0, 2) * 25

			# Rotation
			var angle = offset * (max_angle / center_index) if center_index != 0 else 0

			card.position = Vector2(x, y)
			card.rotation_degrees = angle
