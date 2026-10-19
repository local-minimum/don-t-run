extends Node
@export var terminal: Terminal

@export var title: CanvasLayer
@export var viewport: SubViewport
@export var power_button: Node3D
@export var display: Node3D

@export var floppy: Node3D
@export var floppy_button: Node3D

@export var player_cam: PlayerCam

var _powered_on: bool
var _floppied: bool
enum Hovered { NONE, BUTTON, FLOPPY }
var _hovered = Hovered.NONE
var _titling: bool = true

func _ready() -> void:
    title.show()
    display.scale.y = 0
    terminal.os.game_loaded.connect(_handle_game_loaded)

func _input(event: InputEvent) -> void:
    if _titling:
        if event is InputEventMouseButton || event is InputEventJoypadButton || event is InputEventKey:
            _titling = false
            title.hide()
        return

    if _hovered != Hovered.NONE:
        if event.is_action_pressed("world_select"):
            if _hovered == Hovered.BUTTON && !_powered_on:
                _powered_on = true
                _anim_power_on()
                return
            elif _hovered == Hovered.FLOPPY && !_floppied:
                _floppied = true
                _insert_floppy()
                return

    viewport.push_input(event, true)


func _on_power_mouse_entered() -> void:
    if _powered_on:
        return

    Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
    _hovered = Hovered.BUTTON

func _on_power_mouse_exited() -> void:
    if _hovered == Hovered.BUTTON:
        _hovered = Hovered.NONE
        Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_floppy_mouse_entered() -> void:
    if _floppied:
        return

    Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
    _hovered = Hovered.FLOPPY

func _on_floppy_mouse_exited() -> void:
    if _hovered == Hovered.FLOPPY:
        _hovered = Hovered.NONE
        Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _anim_power_on() -> void:
    var origin: Vector3 = power_button.position
    var t = create_tween()
    t.tween_property(power_button, "position:y", origin.y - 0.005, 0.3)
    t.tween_interval(0.3)
    t.tween_property(power_button, "position", origin, 0.1)
    t.parallel().tween_property(display, "scale:y", 1.0, 0.3)
    t.finished.connect(
        func () -> void:
            terminal.os.powered_on = true
            ,
    )

func _insert_floppy() -> void:
    var cam_start_x: float = player_cam.rotation_degrees.x
    var cam_down_x: float = -44.0
    var pt0: Vector3 = Vector3(0.319, 0.784, 0.3)
    var r0: float = 0.0
    var pt1: Vector3 = Vector3(0.029, 0.784, 0.27)
    var pt2: Vector3 = Vector3(-0.121, 0.783, 0.233)
    var r2: float = 7.9
    var pt3: Vector3 = Vector3(-0.141, 0.783, 0.091)
    var ft = create_tween()
    ft.tween_property(floppy, "position", pt0, 0.7)
    ft.parallel().tween_property(floppy, "rotation_degrees:y", r0, 0.5)
    ft.parallel().tween_property(player_cam, "rotation_degrees:x", cam_down_x, 0.6)
    ft.tween_property(floppy, "position", pt1, 0.4)
    ft.tween_property(floppy, "position", pt2, 0.5)
    ft.parallel().tween_property(floppy, "rotation_degrees:y", r2, 0.4)
    ft.tween_property(floppy, "position", pt3, 0.3)
    ft.parallel().tween_property(floppy_button, "position:z", 0.256, 0.3).set_trans(Tween.TRANS_QUINT)
    ft.parallel().tween_property(player_cam, "rotation_degrees:x", cam_start_x, 0.5)
    ft.finished.connect(
        func () -> void:
            terminal.os.diskett_inserted = true
    )

func _handle_game_loaded() -> void:
    terminal.game.play()
