extends Control
class_name TATerminal

@export var story: TAStory
@export var main_text: TerminalText
@export var input_text: TerminalText
@export var options: OptionsPresenter
@export var input_prefix: String = "> "
@export var input_cursor: String = "{CURSOR 2}"
@export var default_actions: Array[String] = []

var _active: TAEntity
var _doing_action: bool
var _moring: bool
var _action: String
var _target: String

func _enter_tree() -> void:
    story.story_loaded.connect(_handle_story_ready)
    story.executed.connect(_handle_execute_entity)
    main_text.text_done.connect(_handle_main_text_done)
    main_text.text_paused.connect(_handle_more)
    options.select_option.connect(_handle_update_option)
    options.abort_option.connect(_handle_abort_option)

func _ready() -> void:
    _update_input()

func _handle_execute_entity(entity: TAEntity, body: String, title: String) -> void:
    _active = entity
    if entity is TAEdge:
        main_text.clear_text()
    if main_text.text.is_empty():
        main_text.data = title + body
    else:
        main_text.data = "[br][p]%s[/p]%s" % [title, body]

func _handle_story_ready() -> void:
    story.exec_active_node()

func _handle_main_text_done() -> void:
    if _active is TAEdge:
        story.execute_edge_target(_active)
        story.exec_active_node()

    elif _active is TANode:
        _doing_action = true
        _set_actions_options()
        if input_text.data != input_prefix:
            input_text.clear_text()
        input_text.data = input_cursor

func _handle_update_option(value: String) -> void:
    if _moring:
        _moring = false
        main_text.continue_text()
        options.options = []
        options.active = false
        input_text.data = "%sMORE " %  [input_prefix]

        await get_tree().create_timer(0.3).timeout

    if _doing_action:
        _action = value
        _doing_action = false
        _set_referents_options.call_deferred()
    else:
        _target = value
        story.execute_edge_by_command.call_deferred(_action, _target)
        _update_input()

        await get_tree().create_timer(0.3).timeout
        _action = ""
        _target = ""

    _update_input()

func _handle_abort_option() -> void:
    if !_doing_action:
        _doing_action = true
        _set_actions_options()

func _set_actions_options() -> void:
    options.options = story.get_actions(_active, default_actions)
    options.selected = _action

func _set_referents_options() -> void:
    options.options = story.get_referents(_active)
    options.selected = _target

func _update_input() -> void:
    if _action && _target:
        input_text.data = "%s " %  [_target]
    elif _action:
        input_text.data = "%s " %  [_action]
    else:
        input_text.clear_text()
        input_text.data = input_prefix

func _handle_more() -> void:
    _moring = true
    options.options = ["MORE"]
    options.active = true
    input_text.data = input_cursor
