extends Control
class_name TATerminal

enum Phase { INACTIVE, ACTION, REFERANT, COMMIT, MORE }

@export var story: TAStory
@export var main_text: TerminalText2
@export var input_text: TerminalText2
@export var options: OptionsPresenter
@export var input_prefix: String = "> "
@export var input_cursor: TerminalText2.Cursor = TerminalText2.Cursor.UNDERLINE
@export var more_option: String = "MORE"
@export var default_actions: Array[String] = []
@export var delay_show_command: float = 0.5

var _active: TAEntity
var _phase: Phase
var _action: String
var _target: String

func _enter_tree() -> void:
    story.story_loaded.connect(_handle_story_ready)
    story.executed.connect(_handle_execute_entity)
    main_text.text_done.connect(_handle_main_text_done)
    main_text.text_paused.connect(_handle_more)
    input_text.text_done.connect(_handle_input_text_done)
    options.select_option.connect(_handle_update_option)
    options.abort_option.connect(_handle_abort_option)

func _ready() -> void:
    _update_input()

func _input(event: InputEvent) -> void:
    if options.active:
        return

    if event.is_action_pressed("select_option") && main_text.is_anmating():
        main_text.fast_forward()

func _handle_execute_entity(entity: TAEntity, body: String, title: String) -> void:
    _phase = Phase.INACTIVE
    _active = entity
    var instant: bool = entity is TANode && main_text.is_instant()

    if entity is TAEdge || entity == null:
        main_text.clear_text()

    if main_text.is_empty():
        if title:
            main_text.set_data("[p]%s[/p][br]%s" % [title, body])
        elif body.is_empty():
            _handle_main_text_done()
            return
        else:
            main_text.set_data(body)
    else:
        if title:
            main_text.add_data("[br][p]%s[/p][br]%s" % [title, body])
        elif body.is_empty():
            _handle_main_text_done()
            return
        else:
            main_text.add_data("[p][/p][br]%s" % [body])

    if instant:
        main_text.fast_forward()

func _handle_story_ready() -> void:
    story.exec_active_node()

func _handle_main_text_done() -> void:
    if _active is TAEdge || _active == null:
        if _active != null:
            story.execute_edge_target(_active)
        story.exec_active_node()

    elif _active is TANode:
        _phase = Phase.ACTION
        _set_actions_options()
        input_text.show_cursor(input_cursor)
        if !input_text.has_data(input_prefix):
            input_text.fast_forward()
            input_text.set_data(input_prefix)

func _handle_input_text_done() -> void:
    if _phase == Phase.INACTIVE:
        if input_text.has_cursor():
            input_text.remove_cursor()
            if !input_text.has_data(input_prefix):
                input_text.set_data(input_prefix)
    else:
        input_text.restore_default_speeds()
        input_text.show_cursor(input_cursor)

func _handle_update_option(value: String) -> void:
    match _phase:
        Phase.MORE:
            _phase = Phase.INACTIVE
            main_text.play()
            options.options = []
            options.active = false
            input_text.add_data("%s " % value)

            await get_tree().create_timer(delay_show_command).timeout

            if _phase == Phase.INACTIVE:
                _update_input()

        Phase.ACTION:
            _action = value
            _phase = Phase.REFERANT
            _set_referents_options.call_deferred()

            _update_input()

        Phase.REFERANT:
            _phase = Phase.COMMIT
            _target = value
            options.active = false
            options.options = []
            story.execute_edge_by_command.call_deferred(_action, _target)
            _update_input()
            _action = ""
            _target = ""

            await get_tree().create_timer(delay_show_command).timeout

            if _phase == Phase.INACTIVE:
                _update_input()

func _handle_abort_option() -> void:
    if _phase == Phase.REFERANT:
        _phase = Phase.ACTION
        _set_actions_options()
        input_text.set_data(input_prefix)

func _set_actions_options() -> void:
    options.options = story.get_actions(_active, default_actions)
    options.selected = _action
    options.active = true


func _set_referents_options() -> void:
    options.options = story.get_referents(_active)
    options.selected = _target
    options.active = true

func _update_input() -> void:
    if _phase == Phase.INACTIVE:
        input_text.fast_forward()
        input_text.remove_cursor()
        input_text.set_data(input_prefix)
    elif _action && _target:
        input_text.add_data("%s " %  [_target])
    elif _action:
        input_text.add_data("%s " %  [_action])
    else:
        input_text.fast_forward()
        if _phase != Phase.INACTIVE:
            input_text.show_cursor(input_cursor)
        input_text.set_data(input_prefix)

func _handle_more() -> void:
    _phase = Phase.MORE
    options.options = [more_option]
    options.active = true
    input_text.show_cursor(input_cursor)
