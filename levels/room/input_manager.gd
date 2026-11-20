extends Node
@export var terminal: TATerminal
@export var title: CanvasLayer
@export var viewport: SubViewport
@export var power_button: Node3D
@export var power_button_selection: Node3D
@export var display: Node3D
@export var outro: Outro

@export var floppy: Node3D
@export var floppy_button: Node3D
@export var floppy_selection: Node3D

@export var cuppa: Node3D
@export var dialog_player: AudioStreamPlayer
@export var sfx_player: AudioStreamPlayer

@export var scare: AudioStream
@export var should_i: AudioStream
@export var eww: AudioStream
@export var breath: AudioStream
@export var shrug: AudioStream
@export var cold: AudioStream

@export var ground_floor_music: AudioStream
@export var office_music: AudioStream
@export var final_music: AudioStream

@export var player_cam: PlayerCam

const STORY_BOOT_ID: String = "boot"
const STORY_LAUNCH_GAME_ID: String = "play game"
const STORY_ADVENTURE_ID: String = "adventure"

var _booted: bool

var _power_clicked: bool
var _powered_on: bool:
    set(value):
        _powered_on = value
        _booted = false
        terminal.load_story(STORY_BOOT_ID)

var _diskett_clicked
var _diskett_inserted: bool:
    set(value):
        _diskett_inserted = value
        if _booted:
            terminal.load_story(STORY_LAUNCH_GAME_ID)

enum Hovered { NONE, BUTTON, FLOPPY }
var _hovered = Hovered.NONE
var _titling: bool = true

func _ready() -> void:
    cuppa.hide()
    title.show()
    display.scale.y = 0
    terminal.text_event.connect(_handle_text_event)

    floppy_selection.hide()
    power_button_selection.hide()

func _handle_text_event(evt: String) -> void:
    match terminal.active_story_id:
        STORY_BOOT_ID:
            match evt:
                "end":
                    if _diskett_inserted:
                        terminal.load_story(STORY_LAUNCH_GAME_ID)

        STORY_LAUNCH_GAME_ID:
            match evt:
                "end":
                    _handle_game_loaded()
                    terminal.play_music(ground_floor_music)

                "run-game":
                    dialog_player.stop()
                    dialog_player.stream = should_i
                    dialog_player.play()

        STORY_ADVENTURE_ID:
            match evt:
                "cup":
                    _handle_cup()
                "breath":
                    dialog_player.stream = breath
                    dialog_player.play()
                "going-up":
                    terminal.play_music(office_music)
                "typewriter":
                    terminal.play_music(final_music)
                "disgusting":
                    dialog_player.stream = eww
                    dialog_player.play()
                "cold":
                    dialog_player.stream = cold
                    dialog_player.play()
                "shrug":
                    dialog_player.stream = shrug
                    dialog_player.play()
                "end":
                    outro.start_end()
                "cold":
                    outro.set_fog(true)
                "uncold":
                    outro.set_fog(false)

func _input(event: InputEvent) -> void:
    if _diskett_inserted && _powered_on:
        viewport.push_input(event, true)
        return

    if _titling:
        if event is InputEventMouseButton || event is InputEventJoypadButton || event is InputEventKey:
            _titling = false
            title.hide()
        return

    if _hovered != Hovered.NONE:
        if event.is_action_pressed("world_select") || event.is_action_pressed("select_option"):
            if _hovered == Hovered.BUTTON && !_power_clicked:
                power_button_selection.hide()
                _power_clicked = true
                _anim_power_on()
                return
            elif _hovered == Hovered.FLOPPY && !_diskett_clicked:
                floppy_selection.hide()
                _diskett_clicked = true
                _insert_floppy()
                return

    if event.is_action_pressed("prev_option"):
        _hovered = Hovered.BUTTON if _hovered == Hovered.FLOPPY else Hovered.FLOPPY
        if _hovered == Hovered.BUTTON:
            _on_power_mouse_entered()
        else:
            _on_floppy_mouse_entered()
    elif event.is_action_pressed("next_option"):
        _hovered = Hovered.FLOPPY if _hovered == Hovered.BUTTON else Hovered.BUTTON
        if _hovered == Hovered.BUTTON:
            _on_power_mouse_entered()
        else:
            _on_floppy_mouse_entered()

func _on_power_mouse_entered() -> void:
    if _power_clicked:
        return

    floppy_selection.hide()
    power_button_selection.show()
    Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
    _hovered = Hovered.BUTTON

func _on_power_mouse_exited() -> void:
    if _hovered == Hovered.BUTTON:
        _hovered = Hovered.NONE
        Input.set_default_cursor_shape(Input.CURSOR_ARROW)
        power_button_selection.hide()

func _on_floppy_mouse_entered() -> void:
    if _diskett_clicked:
        return

    Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
    floppy_selection.show()
    power_button_selection.hide()
    _hovered = Hovered.FLOPPY

func _on_floppy_mouse_exited() -> void:
    if _hovered == Hovered.FLOPPY:
        _hovered = Hovered.NONE
        Input.set_default_cursor_shape(Input.CURSOR_ARROW)
        floppy_selection.hide()

func _anim_power_on() -> void:
    var origin: Vector3 = power_button.position
    var t = create_tween()
    t.tween_property(power_button, "position:y", origin.y - 0.005, 0.3)
    t.tween_interval(0.3)
    t.tween_property(power_button, "position", origin, 0.1)
    t.parallel().tween_property(display, "scale:y", 1.0, 0.3)
    t.finished.connect(
        func () -> void:
            _powered_on = true
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
            _diskett_inserted = true
    )

func _handle_game_loaded() -> void:
    player_cam.go_play()
    terminal.interactive = true
    terminal.restore_outputs()
    terminal.load_story(STORY_ADVENTURE_ID, false)


func _handle_cup() -> void:
    if cuppa.visible:
        return

    cuppa.show()
    sfx_player.stream = scare
    sfx_player.play()
