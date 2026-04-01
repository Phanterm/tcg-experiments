@tool
extends Panel
class_name Player


## Inverts the player board. Used for displaying the opponent's board.
@export var invert : bool = false:
	set = set_invert

func set_invert(value):
	invert = value
	if value:
		rotation_degrees = 180
	else:
		rotation_degrees = 0

## The starting hand for this player. 
##
## TODO: Currently does nothing.
@export var starting_hand : Array[Card]

## The starting life for this player.
##
## TODO: Currently does nothing.
@export var starting_life : int = 20

## The current life for this player.
##
## TODO: Currently does nothing.
var current_life : int = starting_life

## The starting resources for this player based on gamemode
##
## TODO: implement ui element to represent current amount of treats the player has
@export var max_treats : int = 2
@onready var current_treats : int = max_treats


@export var zone_sandbox : Control
@export var zone_playground : Control
@export var zone_playpen : Control
@export var zone_deck : Control
@export var zone_trash : Control
@export var zone_hand : Control
@export var zone_selected : Control

@export var prompt_window : Prompt

var has_card_selected : bool = false
var selected_card : Card

## The [DeckData] used for this player's deck.
@export var deck : DeckData

func _ready():
	for i in get_children(true):
		if i is Card:
			i.original_owner = self
			i.current_owner = self
	_gather_signals()
	_initialize_zones()
	_showcase_treats()

## Sets up UI text for the current and max treats a player has
func _showcase_treats():
	$"MarginContainer/Current_Max Energy".text = "Treats: " + str(current_treats) + "/" + str(max_treats)

## Sets up the zones for this player so they can be easily accessed.
func _initialize_zones():
	zone_sandbox._assign_slot_properties()
	zone_sandbox.player_owner = self
	zone_playground._assign_slot_properties()
	zone_playground.player_owner = self
	zone_playpen._assign_slot_properties()
	zone_playpen.player_owner = self
	zone_deck._assign_slot_properties()
	zone_deck.player_owner = self
	zone_trash._assign_slot_properties()
	zone_trash.player_owner = self
	zone_hand._assign_slot_properties()
	zone_hand.player_owner = self
	zone_selected._assign_slot_properties()
	zone_selected.player_owner = self


func _gather_signals():
	$"MarginContainer/Card Zones/Hand Zone/Hand".child_order_changed.connect(order_hand)


## This function will automatically sort and arrange cards so they fan out.
func order_hand():
	if !is_instance_valid(self) || !is_instance_valid($"MarginContainer/Card Zones/Hand Zone/Hand"): return
	
	var adj : int = 0
	for i in $"MarginContainer/Card Zones/Hand Zone/Hand".get_children():
		i.z_index = adj
		adj += 1
