@tool
extends Panel

## Card is the base class for all interactive objects containing [CardData] used by players.[br]
## 
## Card is an instance of a player's card from their deck, and can be moved around the field and manipulated.

class_name Card

@export_category("Debug")
## When enabled, activates IMGui related debugging in [member _process].
@export var debug_mode : bool = false

## When enabled, this will produce dragging behavior via [member drag_start].
## Disabling it cancels the dragging behavior via [member drag_cancel].
var dragging : bool = false:
	set = set_dragging

func set_dragging(value):
	if dragging == value: return

	dragging = value
	
	if value:
		if drag_tween && drag_tween.is_running(): drag_tween.custom_step(1000000)
		GameBoard.selected_card = self
		call_deferred("drag_start")
	else:
		GameBoard.selected_card = null
		call_deferred("drag_cancel")

## Used for dragging.
var original_position : Vector2
## Used for dragging.
var original_rotation : float
## Used for dragging.
var original_parent : Control
## Used for dragging.
var original_index : int

## When [member dragging] is set to [code]true[/code], this will record the initial position data in the event that the user cancels the drag.
func drag_start():
	_on_mouse_exit()
	original_parent = get_parent()
	original_index = get_index()
	original_position = global_position
	original_rotation = rotation

	var gpos = global_position
	original_parent.remove_child(self)
	GameBoard.drag_layer.add_child(self)
	global_position = gpos

var drag_tween : Tween

## When [member dragging] is set to [code]false[/code], this will reset the card's position based on values set in [member drag_start].
func drag_cancel():
	GameBoard.clear_preview()
	drag_tween = create_tween()
	drag_tween.tween_property(self, "global_position", original_position, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	await drag_tween.finished

	# Reattach to original parent
	GameBoard.drag_layer.remove_child(self)
	original_parent.add_child(self)
	original_parent.move_child(self, original_index)
	global_position = get_parent().global_position
	_on_mouse_exit()

## This signal is emitted whenever a card is dragged.
signal card_dragged_away(card : Card)

## TODO: Not implemented. This signal is emitted whenever this card is played.
signal card_played(card : Card)

## TODO: Not implemented. This signal is emitted whenever this card's effect activates.
signal card_effect_activated(card : Card)

## TODO: Not implemented. This signal is emitted whenever this card is destroyed.
signal card_destroyed(card : Card)

## TODO: Not implemented. This signal is emitted whenever this card is moved to a new location.
signal card_moved(card : Card, new_location : GameBoard.Zones)

## TODO: Not implemented. This signal is emitted whenever this card changes ownership.
signal card_changed_owner(card : Card)

## Emits when this card is flipped.
signal card_flipped(card : Card, face_down : bool)

## The [Player] who originally owns this card when the match began.
var original_owner : Player

## The [Player] who currently owns this card.
var current_owner : Player: 
	set = set_current_owner

func set_current_owner(value):
	if !is_node_ready(): return

	if current_owner == value: return

	current_owner = value
	card_changed_owner.emit(self)

	## TODO: Need to reparent() the card to the opposing player's board here.


## This card's current location. Changing it emits a signal and moves the position of the card to that location.
var card_location : GameBoard.Zones

var is_selected : bool = false

var can_be_played : bool = false

## Updates this card's location.
func set_card_location(value : GameBoard.Zones):
	if !is_node_ready(): return
	
	if card_location == value: return
	
	card_location = value
	move_card(value)
	card_moved.emit(self, value)

## Manually moves this card to the specified location.
func move_card(new_location : GameBoard.Zones):
	## return
	var destination
	match new_location:
		GameBoard.Zones.Hand:
			destination = current_owner.zone_hand
		GameBoard.Zones.Deck:
			destination = current_owner.zone_deck
		GameBoard.Zones.Playpen:
			destination = current_owner.zone_playpen
		GameBoard.Zones.Sandbox:
			destination = current_owner.zone_sandbox
		GameBoard.Zones.Playground:
			destination = current_owner.zone_playground
		GameBoard.Zones.Trash:
			destination = current_owner.zone_trash
		GameBoard.Zones.Selected:
			destination = current_owner.zone_selected
			print_debug("IN SELECTED ZONE")
			if GameBoard.current_player.current_treats >= card_data.card_cost:
				can_be_played = true
				GameBoard.current_player.prompt_window.set_selected_text(self)
				print_debug("CARD CAN BE PLAYED")
			else:
				GameBoard.current_player.prompt_window.set_selected_text(self)
				print_debug("CARD CANNOT BE PLAYED")
		GameBoard.Zones.Custom:
			destination = current_owner
	global_position = destination.global_position

## The [CardData] which makes up this card's contents.
@export var card_data : CardData

@onready var front : Control = $Front
@onready var back : Control = $Back

var flip_tween : Tween
var hover_tween : Tween

## Determines which side this card is facing. A value of [code]true[/code] indicates that this card is currently face-down.
var flipped : bool = false:
	set = set_flipped

func set_flipped(value):
	if flipped == value: return

	if flip_tween && flip_tween.is_running():
		return

	flipped = value

	flip_card()

## Manually flips the card, creating a [Tween] to facilitate this animation.
func flip_card():
	var card_in : Control
	var card_out : Control

	if flipped:
		card_in = front
		card_out = back

	else:
		card_in = back
		card_out = front

	flip_tween = create_tween()
	flip_tween.tween_property(card_out, "scale:x", 0.001, 0.25)
	flip_tween.tween_property(card_out, "visible", false, 0.001)
	flip_tween.tween_property(card_in, "visible", true, 0.001)
	flip_tween.tween_property(card_in, "scale:x", 1, 0.25)
	await flip_tween.finished
	
	if flipped:
		card_flipped.emit(self, true)
	else:
		card_flipped.emit(self, false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_data()
	_gather_signals()

func _gather_signals():
	if !Engine.is_editor_hint():
		card_flipped.connect(GameBoard.on_card_flipped)
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)
	gui_input.connect(_on_gui_input)

## Checks to see if this card can be selected on the current turn by the current player.
func _can_select() -> bool:
	if current_owner == GameBoard.player_human && GameBoard.current_player == GameBoard.player_human:
		return true
	else:
		return false

func _on_mouse_enter():
	if dragging || !_can_select(): return

	#print("Mouse Enter")
	GameBoard.highlighted_card = self
	$Highlight.visible = true
	if hover_tween && hover_tween.is_running():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(get_parent(), "position:y", -32, 0.2)

func _on_mouse_exit():
	if dragging || !_can_select(): return
	$Highlight.visible = false
	GameBoard.highlighted_card = null
	#print("Mouse Exit")
	
	if hover_tween && hover_tween.is_running():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(get_parent(), "position:y", 32, 0.15)

func _on_gui_input(event : InputEvent):
	if !_can_select() || dragging: return

	if event is InputEventMouseButton:
		if event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
			if !is_selected:
				reparent($"../../../../Selected Zone/CenterContainer/CardSlot")
				set_card_location(GameBoard.Zones.Selected)
				is_selected = true
				print_debug("CARD IS SELECTED")
				get_viewport().set_input_as_handled()
			else:
				print_debug("CARD ALREADY SELECTED")

func _input(event : InputEvent):
	if !_can_select(): return

	if dragging && event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false

	if event.is_action_pressed("ui_accept"):
		flipped = !flipped

## Pulls data from [member card_data] defined by [CardData].
func get_data():
	if card_data:
		set_card_color(card_data.card_color)
		$Front/MainMargin/ContentMargin/Body/BodyMargin/RichTextLabel.text = card_data.card_text
		$Front/MainMargin/ContentMargin/Title/RichTextLabel.text = card_data.card_name
		$Front.self_modulate = card_data.card_border_color
		$Front/CardCost.text = "cost: " + str(card_data.card_cost)
	else:
		printerr("get_data() FAIL: No CardData provided for card " + name + "!")

## Helper function to more cleanly set text on the card's title.
func set_card_title_text(new_text : String):
	$Front/MainMargin/ContentMargin/Title/RichTextLabel.text = new_text

## Helper function to more cleanly set text on the card's body.
func set_card_body_text(new_text : String):
	$Front/MainMargin/ContentMargin/Body/RichTextLabel.text = new_text

## Helper function to more cleanly set the card's main color.
func set_card_color(color : Color):
	$Front/MainMargin/ContentMargin/Title.self_modulate = color
	$Front/MainMargin/ContentMargin/Body.self_modulate = color

## Helper function to more cleanly set the card's main color.
func set_card_border_color(color : Color):
	$Front.self_modulate = color

func _get_drag_data(at_position: Vector2) -> Variant:
	#set_drag_preview(get_drag_preview())
	return self

## DEPRECATED: We move the card directly rather than create a preview using Godot's built-in system.
#func get_drag_preview() -> Control:
	#var new_preview : Control
	#if !flipped:
		#new_preview = $Front.duplicate()
	#else:
		#new_preview = $Back.duplicate()
	#new_preview.set_anchors_preset(Control.PRESET_CENTER)
	#return new_preview

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position()
	
	if debug_mode && !Engine.is_editor_hint():
		ImGui.Begin("CARD INFO")
		if !card_data:
			ImGui.Text("==NO CARD DATA==")
			ImGui.End()
		else:
			ImGui.Text("Card Name: " + str(card_data.card_name))
			if current_owner:
				ImGui.Text("Card Owner: " + str(current_owner))
			else:
				ImGui.Text("Card Owner: ==NO OWNER==")
		ImGui.Text("Original Parent: " + str(original_parent))
		ImGui.Text("Current Parent: " + str(get_parent().name))
		ImGui.End()
