extends CanvasLayer

var size_screen_x = 0
var size_screen_y = 0

func _ready():
	update_screen_size()

func _process(delta):
	delta = delta
	if get_viewport().size.x != size_screen_x or get_viewport().size.y != size_screen_y:
		update_screen_size()

func update_screen_size():
	size_screen_x = get_viewport().size.x
	size_screen_y = get_viewport().size.y
	
	$ColorRect.rect_position.x = (size_screen_x - $ColorRect.rect_size.x) / 2
	$ColorRect.rect_position.y = (size_screen_y - $ColorRect.rect_size.y) / 2
	
