extends Panel
class_name CardCreature

## TODO: Not implemented. This signal emits when this card would damage another player.
signal card_damaged_player(card : Card, amount : int)

## TODO: Not implemented. This signal emits when this card would be damaged by another card's effect.
signal card_damaged_by_effect(card : Card, amount : int)

## TODO: Not implemented. This signal emits when this card would be dealt damage by another creature.
signal card_damaged_by_creature(card : Card, attacking_creature : Card, amount : int)

## TODO: Not implemented. This signal emits when this card would deal damage to another creature.
signal card_damaged_creature(card : Card, defending_creature : Card, amount : int)

## TODO: Not implemented. This signal emits when this card would be destroyed by another creature.
signal card_destroyed_by_creature(card : Card, attacking_creature : Card)

## TODO: Not implemented. This signal emits when this card would destroy another creature.
signal card_destroyed_creature(card : Card, destroyed_creature : Card)
