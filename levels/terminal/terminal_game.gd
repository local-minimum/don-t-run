extends Node

@export var autoplay: bool

@export var main: TerminalText
@export var input: TerminalText
@export var options: Control

@export var start: GamePlace
@export var input_prefix: String = "{CLEAR}{SPEED 0}{CURSOR 1 0.2}> "
@export var default_actions: Array[String] = [GamePlace.ACTION_LOOK, GamePlace.ACTION_GO, GamePlace.ACTION_USE, GamePlace.ACTION_TAKE]

var carried: Array[GameBit]
var current: GamePlace
var _action: String
var _target: String
var _actions: Array[String]
var _targets: Array[String]

func _ready() -> void:
    if autoplay:
        play()

func play() -> void:
    main.clear_text()
    main.set_defaults()
    main.show()
    if !main.text_event.is_connected(_handle_text_event):
        main.text_event.connect(_handle_text_event)

    input.clear_text()
    input.set_defaults()
    input.show()
    input.data = input_prefix

    options.show()

    if current == null:
        current = start

    start_current()

func start_current() -> void:
    main.text_done.connect(_handle_description_done, CONNECT_ONE_SHOT)
    main.data = current.description

func _handle_description_done() -> void:
    input.data = input_prefix
    _actions.clear()
    _targets.clear()
    _action = ""
    _target = ""

    _actions.append_array(default_actions)
    for i: GameInteraction in carried:
        i.append_trigger_actions(_actions)
        i.append_trigger_targets(_targets)

    for a: String in current.actions:
        if !_actions.has(a):
            _actions.append(a)

    for t: String in current.targets:
        if !_targets.has(t):
            _targets.append(t)

    print_debug(_actions, _targets)
func _handle_text_event(_evt: String) -> void:
    pass
