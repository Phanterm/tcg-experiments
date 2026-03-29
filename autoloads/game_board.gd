extends Control

## GameBoard is the global instance that handles processing turn phases, contains reference to both [br]
## [Player]s, and handles other functions like previews, card dragging, and global signal handling.

## This signal emits at the beginning of the current turn.
signal phase_snack_time

## This signal emits when the Draw Phase begins, before drawing a card.
signal phase_draw

## This signal emits when the Migrate Phase begins.
signal phase_migrate

## This signal emits when the Refresh Phase begins.
## signal phase_refresh

## This signal emits when the Action Phase begins.
signal phase_action

## This signal emits when a Combat Phase would begin.
signal phase_combat

## This signal emits when a Secondary Phase would begin.
## signal phase_secondary

## This signal emits right before the turn would end.
signal phase_end

## This signal emits after the end phase, and is used for resetting the board state if needed.
signal phase_cleanup

## Phases represent the parts of a turn wherein cards may be played and other actions may be taken.
enum Phases {
	SnackTime,
	Draw,
	Migrate,
## 	Refresh,
	Action,
	Combat,
## 	Secondary,
	End,
	Cleanup
}

## The current phase of the turn.
var current_phase : Phases

## The player who has control during this turn.
var current_player : Player

## Switches control of [member current_player] at the start of a new turn.
func change_turn():
	turns_till_next_round -= 1
	if turns_till_next_round == 0:
		current_round += 1
		turns_till_next_round = number_of_players
	if !current_player:
		current_player = player_human
		return

	if current_player == player_human:
		current_player = player_cpu
	elif current_player == player_cpu:
		current_player = player_human

@onready var player_human : Player = $"MarginContainer/Play Area/Blue Player"
@onready var player_cpu : Player = $"MarginContainer/Play Area/Red Player"
@onready var current_round : int = 0
@export var number_of_players : int = 0
@onready var turns_till_next_round : int = number_of_players

## The [Card] currently being dragged by the player.
var selected_card : Card

## The [Card] currently being highlighted for the purposes of displaying a preview.
var highlighted_card : Card:
	set = set_highlighted_card

func set_highlighted_card(value):
	if !is_node_ready() || highlighted_card == value: return
	
	if highlighted_card && value == null:
		highlighted_card.z_index -= 50
	
	highlighted_card = value
	
	if highlighted_card:
		highlighted_card.z_index += 50
		preview_timer.start()
	else:
		clear_preview()

## Zones represent parts of the game board used to determine which card placements are legal.
enum Zones {
	Deck,
	Hand,
	Playpen,
	Playground,
	Sandbox,
	Trash,
	Selected,
	Custom
}

@onready var preview_timer : Timer = $PreviewTimer
@onready var drag_layer : Control = $"MarginContainer/Play Area/Drag Layer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_phase = Phases.SnackTime
	_set_interactable()
	_gather_signals()
	_initialize_round()

## Begins the match.
func _initialize_round():
	change_turn()
	turns_till_next_round = number_of_players
	player_human.max_treats = 2
	player_cpu.max_treats = 2
	## current_round += 1
	current_phase = Phases.SnackTime
	phase_snack_time.emit()

func _gather_signals():
	preview_timer.timeout.connect(_update_preview)

## Updates the preview when highlighting a card.
func _update_preview():
	if !is_instance_valid($Preview): return
	if highlighted_card == null: return
	
	var new_preview = highlighted_card.find_child("Front").duplicate()
	$Preview.add_child(new_preview)
	new_preview.size = $Preview.size

## Clears the preview zone.
func clear_preview():
	preview_timer.stop()
	if $Preview.get_child_count() > 0:
		$Preview.get_child(0).queue_free()

## Ensures that every [Control] node is not interactable except [Card]s, [CardSlot]s, and [Button]s.
func _set_interactable():
	for i in get_children(true):
		if i is Card || i is CardSlot || i is Button:
			i.mouse_filter = MOUSE_FILTER_PASS
			i.mouse_behavior_recursive = MOUSE_BEHAVIOR_ENABLED
		elif i is Control || i is Panel:
			i.mouse_filter = MOUSE_FILTER_IGNORE
			i.mouse_behavior_recursive = MOUSE_BEHAVIOR_DISABLED
	for i in $Debug.get_children(true):
		i.mouse_filter = MOUSE_FILTER_STOP
		i.mouse_behavior_recursive = MOUSE_BEHAVIOR_ENABLED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !Engine.is_editor_hint():
		ImGui.Begin("TURN INFO")
		if current_player && current_player == player_cpu:
			ImGui.Text("Current Player: CPU")
		elif current_player && current_player == player_human:
			ImGui.Text("Current Player: Human")
		ImGui.Text("Current Phase: " + Phases.keys()[current_phase])
		ImGui.Text("Current Round: " + str(current_round))
		ImGui.End()

		if selected_card:
			ImGui.Begin("SELECTED CARD")
			ImGui.Text("Name: " + selected_card.card_data.card_name)
			ImGui.Text("Card Origin: " + str(selected_card.original_parent.get_parent().name))
			ImGui.End()

func on_card_flipped(card : Card, face_down : bool):
	if face_down:
		print("Card: " + card.card_data.card_name + " flipped face down!")
	else:
		print("Card: " + card.card_data.card_name + " flipped face up!")

## Progresses the phase of the turn by changing [member current_phase] and emitting the appropriate signal for this.
func advance_phase() -> void:
	match current_phase:
		Phases.SnackTime:
			current_phase = Phases.Draw
			phase_draw.emit()
		Phases.Draw:
			current_phase = Phases.Migrate
			phase_migrate.emit()
		Phases.Migrate:
			current_phase = Phases.Action
			phase_action.emit()
##		Phases.Refresh:
##			current_phase = Phases.Main
##			phase_main.emit()
		Phases.Action:
			current_phase = Phases.Combat
			phase_combat.emit()
		Phases.Combat:
			current_phase = Phases.End
			phase_end.emit()
##		Phases.Secondary:
##			current_phase = Phases.End
##			phase_end.emit()
		Phases.End:
			current_phase = Phases.Cleanup
			phase_cleanup.emit()
		Phases.Cleanup:
			change_turn()
			current_phase = Phases.SnackTime
			if (current_round % 2 == 0 && current_round != 0):
				current_player.max_treats += 1
			current_player.current_treats = current_player.max_treats
			current_player._showcase_treats()
			phase_snack_time.emit()
