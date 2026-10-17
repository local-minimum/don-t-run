extends Node

@export var main: TerminalText
@export var input: TerminalText
@export var options: Control

@export_multiline() var boot_sequence: String

func _ready() -> void:
    input.autoplay = true
    input.autoclear = true
    input.data = ""
    input.hide()

    options.hide()

    main.data = boot_sequence
    if !main.autoplay:
        main.play()
