extends Node
@export var player_cam: PlayerCam

@export var terminal: TATerminal
@export var typewriter: Node3D
@export var computer: Node3D
@export var floppy: Node3D
@export var snowman: Node3D
@export var snowman_spot: SpotLight3D
@export var end_ui: CanvasLayer

@export var player: AudioStreamPlayer
@export var end_scare: AudioStream
@export var fog: Node3D

func _ready() -> void:
    terminal.text_event.connect(_handle_text_event)
    typewriter.hide()
    computer.show()
    fog.hide()
    floppy.show()
    snowman.hide()
    snowman_spot.hide()
    end_ui.hide()

func _handle_text_event(evt: String) -> void:
    if terminal.active_story_id != "adventure":
        return

    match evt:
        "end":
            _handle_outro()
        "cold":
            fog.visible = true
        "uncold":
            fog.visible = false

func _handle_outro() -> void:
    var t1: float = 0.05
    var t2: float = 0.025
    player.stream = end_scare
    floppy.hide()
    computer.hide()
    typewriter.show()
    player_cam.go_start_pos(0.2)
    await get_tree().create_timer(t1).timeout
    typewriter.hide()
    await get_tree().create_timer(t2).timeout
    typewriter.show()
    await get_tree().create_timer(t1).timeout
    typewriter.hide()
    await get_tree().create_timer(t2).timeout
    typewriter.show()
    await get_tree().create_timer(3.0).timeout
    snowman.show()
    await get_tree().create_timer(0.05).timeout
    player.play()
    snowman_spot.show()
    await get_tree().create_timer(5.0).timeout
    end_ui.show()
