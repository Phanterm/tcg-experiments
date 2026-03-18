@tool
extends Control

## CardSlot hold [Card]s and contain data based on where the slot is placed. [br]
## 
## Handles and filters which cards may be legally placed within it.

class_name CardSlot

## The type of zone this slot represents. Determines how [Card]s of different types can interact with this slot.
@export var slot_type : GameBoard.Zones

var indicator_tween : Tween

## Returns whether or not a [Card] occupies this slot as an immediate child node. Returns [code]null[/code] if no [Card] is found.
func get_card() -> Variant:
	if get_child_count() == 0: 
		return null
	return get_child(0) as Card

## When enabled, the slot will pulse slowly to indicate interactability. When disabled, this effect will reset.
@export var active : bool:
	set = set_active

func set_active(value):
	active = value
	self_modulate.a = 0

	if value:
		self_modulate.a = 1
		run_indicator()
	else:
		if indicator_tween && indicator_tween.is_running():
			indicator_tween.kill()
			self_modulate.a = 0

## This function fires when a [Card] is dragged away from this slot.
func dragged_away(card : Card) -> void:
	card.card_dragged_away.disconnect(dragged_away)
	remove_child(card)

## This function fires when a dragged [Card] is added to this slot.
func add_card(card : Card) -> void:
	card.card_dragged_away.connect(dragged_away)
	add_child(card)

## Filters out which dragged [Card]s may be placed within this slot.
func _can_drop_data(_at_position : Vector2, data : Variant) -> bool:
	if data is Card:
		match (data as Card).card_location:
			GameBoard.Zones.Deck:
				return false
			GameBoard.Zones.Hand:
				if slot_type == GameBoard.Zones.Playpen:
					return true
				if slot_type == GameBoard.Zones.Playground:
					return true
				if slot_type == GameBoard.Zones.Sandbox:
					return true
				return false
			GameBoard.Zones.Trash:
				return false
			GameBoard.Zones.Playpen:
				if slot_type == GameBoard.Zones.Playground:
					return true
				return false
			GameBoard.Zones.Playground:
				return false
			GameBoard.Zones.Sandbox:
				return false
			GameBoard.Zones.Custom:
				return true
	return false

func _ready():
	active = false

## When [member _can_drop_data] returns [code]true[/code], this function handles adding the [Card] to this slot.
func _drop_data(_at_position : Vector2, data : Variant) -> void:
	var card : Card = data as Card
	card.dragged_away.emit(card)
	card.card_location = slot_type
	add_card(card)

## Sets the location for any card that is initially on the [Player]'s board.
func initialize_slot():
	if get_card():
		get_card().card_location = slot_type

## Handles the [Tween] used to pulse this slot when [member active] is set to [code]true[/code].
func run_indicator():
	if indicator_tween && indicator_tween.is_running():
		indicator_tween.kill()

	indicator_tween = create_tween().set_loops()
	indicator_tween.tween_property(self, "self_modulate:a", 0.9, 0.5)
	indicator_tween.tween_property(self, "self_modulate:a", 0.1, 0.5)
