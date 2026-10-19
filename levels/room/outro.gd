extends Node

@export var terminal: Terminal
@export var typewriter: Node3D
@export var computer: Node3D
@export var floppy: Node3D
@export var snowman: Node3D
@export var snowman_spot: SpotLight3D

func _ready() -> void:
    terminal.mist.connect(_handle_mist)
    terminal.outro.connect(_handle_outro)
    typewriter.hide()
    computer.show()
    floppy.show()
    snowman.hide()
    snowman_spot.hide()

func _handle_outro() -> void:
    var t1: float = 0.05
    var t2: float = 0.025
    floppy.hide()
    computer.hide()
    typewriter.show()
    await get_tree().create_timer(t1).timeout
    typewriter.hide()
    await get_tree().create_timer(t2).timeout
    typewriter.show()
    await get_tree().create_timer(t1).timeout
    typewriter.hide()
    await get_tree().create_timer(t2).timeout
    typewriter.show()
    await get_tree().create_timer(0.5).timeout
    snowman.show()
    await get_tree().create_timer(0.05).timeout
    snowman_spot.show()

func _handle_mist(on: bool) -> void:
    pass
