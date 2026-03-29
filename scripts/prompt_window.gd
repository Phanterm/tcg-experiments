@tool
extends Panel
class_name Prompt

## Prompt Window is the class that reads in a cards data and outputs as respective text within

@export var p_text : String = ""

func set_selected_text(selected_card : Card):
	var data : CardData = selected_card.card_data
	if(selected_card.can_be_played):
		p_text = "Do you want to play " + data.card_name + " for " + str(data.card_cost) + " treats? \n"
		if(data.card_type == "Little Guy"):
			p_text += "When played, this card will enter the Playpen \n"
		elif(data.card_type == "Bit" || data.card_type == "Bauble"):
			p_text += "When played, this card will enter the Sandbox \n"
		else:
			p_text += "When played, this card will enter the Trash \n"
	else:
		p_text = "You cannot play " + data.card_name + ". You need " + str(data.card_cost - GameBoard.current_player.current_treats) + " more treats until you may play this card. \n"
	
	p_text += "Card Type: " + data.card_type + "\n"
	p_text += "Card Text: " + data.card_text 
	$"Border/Inner Margin/Panel/TextMargin/PromptText".text = p_text

func clear_selected_text():
	$"Border/Inner Margin/Panel/TextMargin/PromptText".text = ""

@onready var play_button : Button = $HBoxContainer/PlayCardButton
@onready var return_button : Button = $HBoxContainer/ReturnButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_button = $HBoxContainer/PlayCardButton
	return_button = $HBoxContainer/ReturnButton
	_set_interactable()
	play_button.pressed.connect(_on_play_card_button_pressed)
	return_button.pressed.connect(_on_return_button_pressed)
	print($HBoxContainer.mouse_filter)
	pass

func _on_play_card_button_pressed() -> void:
	print_debug("play pressed")
	if(GameBoard.current_player.has_card_selected):
		GameBoard.current_player.selected_card.play_button_pressed()
	else:
		print_debug("No card selected")
	return

func _on_return_button_pressed() -> void:
	print_debug("return pressed")
	if(GameBoard.current_player.has_card_selected):
		GameBoard.current_player.selected_card.return_button_pressed()
	else:
		print_debug("No card selected")
	return
	

func _set_interactable():
	for i in get_children(true):
		if i is Card || i is CardSlot || i is Button || i is BoxContainer:
			i.mouse_filter = MOUSE_FILTER_PASS
			i.mouse_behavior_recursive = MOUSE_BEHAVIOR_ENABLED
		#elif i is Control || i is Panel:
		#	i.mouse_filter = MOUSE_FILTER_IGNORE
		#	i.mouse_behavior_recursive = MOUSE_BEHAVIOR_DISABLED


func get_play_button():
	return play_button

func get_return_button():
	return return_button

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
