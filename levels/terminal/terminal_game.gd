extends Node
class_name TerminalGame

@export var term: Terminal

@export var autoplay: bool

@export var main: TerminalText
@export var input: TerminalText
@export var options: OptionsPresenter

@export var start: GamePlace
@export var input_prefix: String = "{CLEAR}{SPEED 0}{CURSOR 1 0.2}> "
@export var default_actions: Array[String] = [GamePlace.ACTION_LOOK, GamePlace.ACTION_GO, GamePlace.ACTION_USE, GamePlace.ACTION_TAKE]

@export var ground_music: AudioStream

@export var office_music: AudioStream
@export var final_music: AudioStream

@export var dialog_player: AudioStreamPlayer
@export var breath: AudioStream
@export var eww: AudioStream
@export var shrug: AudioStream
@export var cold: AudioStream

var carried: Array[GameInteraction]
var current: GamePlace
var _active: GameBit:
    set(value):
        if _active && _active.first_time:
            _active.first_time = false
        _active = value
var _action: String
var _target: String
var _actions: Array[String]
var _targets: Array[String]
var state: Array[String]

func _ready() -> void:
    options.abort_option.connect(_show_actions)
    main.text_paused.connect(_handle_more)

    if autoplay:
        play()

func play() -> void:
    term.play_music(ground_music)
    main.clear_text()
    main.set_defaults()
    main.show()
    if !main.text_event.is_connected(_handle_text_event):
        main.text_event.connect(_handle_text_event)

    input.clear_text()
    input.set_defaults()
    input.show()
    _update_input()

    options.show()
    options.active = false

    if current == null:
        current = start

    start_current()

func _update_input() -> void:
    if _action && _target:
        input.data = "%s%s %s " %  [input_prefix, _action, _target]
    elif _action:
        input.data = "%s%s " %  [input_prefix, _action]
    else:
        input.data = input_prefix

func start_current() -> void:
    _active = current
    current.sync(self)
    main.text_done.connect(_handle_description_done, CONNECT_ONE_SHOT)
    main.data = current.get_extended_description(self)

func _handle_description_done() -> void:
    input.data = input_prefix
    _actions.clear()
    _targets.clear()
    _action = ""
    _target = ""

    _actions.append_array(default_actions)

    for a: String in current.actions:
        if !_actions.has(a):
            _actions.append(a)

    for t: String in current.targets:
        if !_targets.has(t):
            _targets.append(t)

    for i: GameInteraction in carried:
        i.append_trigger_actions(_actions)
        i.append_trigger_targets(_targets)

    _show_actions()

func _show_actions() -> void:
    options.active = true
    options.options = _actions
    options.selected = _action
    _action = ""
    _update_input()
    if options.select_option.is_connected(_handle_target_selected):
        options.select_option.disconnect(_handle_target_selected)
    options.select_option.connect(_handle_action_selected, CONNECT_ONE_SHOT)

func _handle_action_selected(action: String) -> void:
    if action && action in _actions:
        _action = action
        _update_input()
        _show_targets()

func _show_targets() -> void:
    options.options = _targets
    options.selected = ""
    options.select_option.connect(_handle_target_selected, CONNECT_ONE_SHOT)

func _handle_target_selected(target: String) -> void:
    if target && target in _targets:
        _target = target
        options.active = false
        options.options = []
        _update_input()

        var opt: GameBit = current.get_bit(_action, _target)
        if opt == null:
            for c in carried:
                if c.triggers.has("%s %s" % [_action, _target]):
                    opt = c
                    break
        main.clear_text()
        main.text_done.connect(_do_selected_option.bind(opt), CONNECT_ONE_SHOT)
        main.data = "[i]> %s %s[/i]\n\n" % [_action, _target]

func _do_selected_option(option: GameBit) -> void:
    var previous: GamePlace = current
    if current.auto_increment_description:
        current.active_description += 1

    if option is GameTransition:
        if option.place:
            current = option.place
        else:
            push_error("%s leads to nowhere" % option)
    elif option is GameInteraction:
        if option.autohide:
            option.hidden = true
        if option.add_targets:
            for t: String in option.add_targets:
                if !current.added_targets.has(t):
                    current.added_targets.append(t)
        if option.autoblock:
            option.blocked = true
        if option.pickup:
            carried.append_array(option.pickup)

    main.text_done.connect(start_current, CONNECT_ONE_SHOT)
    _active = option
    if option == null:
        if _action == "LOOK":
            main.data = "You see nothing special.\n\n"
        else:
            main.data = "You cannot do that.\n\n"
    else:
        main.data = "%s\n\n" % option.description
        if option.auto_increment_description:
            option.active_description += 1

        for s: String in option.add_state:
            if !previous.state.has(s):
                previous.state.append(s)
        for s: String in option.remove_state:
            if previous.state.has(s):
                previous.state.erase(s)
        for s: String in option.add_global_state:
            if !state.has(s):
                state.append(s)

    _action = ""
    _target = ""
    _update_input()

func _handle_more() -> void:
    options.options = ["MORE"]
    if options.abort_option.is_connected(_show_actions):
        options.abort_option.disconnect(_show_actions)
    options.select_option.connect(_continue_more, CONNECT_ONE_SHOT)
    options.active = true
    input.data = input_prefix

func _continue_more(_opt: String) -> void:
    main.continue_text()
    options.abort_option.connect(_show_actions)
    options.options = []
    options.active = false
    input.data = "%sMORE " %  [input_prefix]
    await get_tree().create_timer(0.3).timeout
    if input.data.contains("MORE"):
        input.data = input_prefix

func _handle_text_event(evt: String) -> void:
    if evt == "breath":
        dialog_player.stream = breath
        dialog_player.play()
    elif evt == "going-up":
        term.play_music(office_music)
    elif evt == "typewriter":
        term.play_music(final_music)
    elif evt == "disgusting":
        dialog_player.stream = eww
        dialog_player.play()
    elif evt == "cold":
        dialog_player.stream = cold
        dialog_player.play()
        term.mist.emit(true)
    elif evt == "uncold":
        term.mist.emit(false)
    elif evt == "shrug":
        dialog_player.stream = shrug
        dialog_player.play()
    elif evt == "end":
        pass
    else:
        push_warning("Event not handled: '%s' during %s" % [evt, _active])
