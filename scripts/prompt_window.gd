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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
