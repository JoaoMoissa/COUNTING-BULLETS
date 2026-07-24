extends CenterContainer

@export var DOT_RADIUS : float = 2.0
@export var DOT_COLOR : Color = Color.WHITE


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(size / 2.0, DOT_RADIUS,DOT_COLOR)
