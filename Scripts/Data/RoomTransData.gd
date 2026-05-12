extends Resource

class_name RoomTransData

@export var room_id: int
@export var player_x: float
@export var player_y: float
@export var entrance_way: EntranceWay

enum EntranceWay { TOP, BOTTOM, LEFT, RIGHT }
