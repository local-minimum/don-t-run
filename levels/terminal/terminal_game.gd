extends Node
class_name TerminalGame

@export var autoplay: bool

@export var main: TerminalText
@export var input: TerminalText
@export var options: OptionsPresenter

@export var start: GamePlace
@export var input_prefix: String = "{CLEAR}{SPEED 0}{CURSOR 1 0.2}> "
@export var default_actions: Array[String] = [GamePlace.ACTION_LOOK, GamePlace.ACTION_GO, GamePlace.ACTION_USE, GamePlace.ACTION_TAKE]

var carried: Array[GameInteraction]
var current: GamePlace
var _action: String
var _target: String
var _actions: Array[String]
var _targets: Array[String]

func _ready() -> void:
    options.abort_option.connect(_show_actions)

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
    current.sync(self)
    main.text_done.connect(_handle_description_done, CONNECT_ONE_SHOT)
    main.data = current.extended_description

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
        main.data = "\n\n[i]> %s %s[/i]\n\n" % [_action, _target]

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
            current.added_targets.append_array(option.add_targets)
        if option.pickup:
            carried.append_array(option.pickup)

    main.text_done.connect(start_current, CONNECT_ONE_SHOT)
    if option == null:
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

    _action = ""
    _target = ""
    _update_input()

func _handle_text_event(_evt: String) -> void:
    pass
