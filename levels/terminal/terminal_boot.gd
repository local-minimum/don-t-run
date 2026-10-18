extends Node
class_name TerminalOS

@export var main: TerminalText
@export var input: TerminalText
@export var options: Control

@export_multiline() var boot_sequence: String
@export_multiline() var load_game_squence: String

var _booted: bool

@export var powered_on: bool:
    set(value):
        powered_on = value
        _booted = false
        _power_on()

@export var diskett_inserted: bool:
    set(value):
        diskett_inserted = value
        if _booted:
            _load_game()

func _ready() -> void:
    if powered_on:
        _power_on()

func _power_on() -> void:
    input.autoplay = true
    input.autoclear = true
    input.data = ""
    input.hide()

    options.hide()
    _start_boot()

func _start_boot() -> void:
    main.text_done.connect(_handle_boot_done, CONNECT_ONE_SHOT)
    main.data = boot_sequence
    if !main.autoplay:
        main.play()


func _handle_boot_done() -> void:
    _booted = true
    main.autoclear = false
    if diskett_inserted:
        _load_game()

func _load_game() -> void:
    await get_tree().create_timer(1.0).timeout
    main.text_done.connect(_handle_loaded_game, CONNECT_ONE_SHOT)
    main.data = load_game_squence
    if !main.autoplay:
        main.play()

func _handle_loaded_game() -> void:
    pass
