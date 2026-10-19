extends Camera3D
class_name PlayerCam

@export var game_pos: Node3D
@export var start_pos: Node3D

func go_play() -> void:
    var t: Tween = create_tween()
    t.tween_property(self, "global_position", game_pos.global_position, 1.0)
    t.parallel().tween_property(self, "global_rotation", game_pos.global_rotation, 1.0)

func go_start_pos(duration: float = 1.0) -> void:
    var t: Tween = create_tween()
    t.tween_property(self, "global_position", start_pos.global_position, duration)
    t.parallel().tween_property(self, "global_rotation", start_pos.global_rotation, duration)
