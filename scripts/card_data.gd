extends Resource

## CardData is the base class for all card information that is loaded into a [Card] [br]
## 
## Contains information about the card's name, image used, body text, and card color.
## When a [Card] is initialized, it will search for an associated [CardData].

class_name CardData

## The name of the card.
@export var card_name : String = "Card Title"

## The image used for the card.
@export var card_image : Texture2D

## The body text used for the card.
@export var card_text : String = "Body text"

## The color of the card body area.
@export var card_color : Color = Color.WHITE

## The color of the card border.
@export var card_border_color : Color = Color.WHITE
