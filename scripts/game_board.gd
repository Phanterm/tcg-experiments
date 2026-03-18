extends Control
class_name Board



var dragging : bool = false  # Are we currently dragging?
var selected : Array[Control] = []  # Array of selected units.
var drag_start : Vector2 = Vector2.ZERO  # Location where drag began.
var select_rect : RectangleShape2D = RectangleShape2D.new()  # Collision shape for drag box.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
