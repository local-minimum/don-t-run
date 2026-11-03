extends Control
class_name TATerminal

@export var story: TAStory
@export var main_text: TerminalText
@export var input_text: TerminalText
@export var options: OptionsPresenter
@export var input_prefix: String = "> "
@export var default_actions: Array[String] = []

var _active: TAEntity
var _action: String
var _target: String

func _enter_tree() -> void:
    story.story_loaded.connect(_handle_story_ready)
    story.executed.connect(_handle_execute_entity)
    main_text.text_done.connect(_handle_main_text_done)

func _ready() -> void:
    _update_input()

func _handle_execute_entity(entity: TAEntity, body: String, title: String) -> void:
    _active = entity
    main_text.data = title + body

func _handle_story_ready() -> void:
    story.exec_active_node()

func _handle_main_text_done() -> void:
    if _active is TAEdge:
        story.execute_edge_target(_active)
        story.exec_active_node()
    elif _active is TANode:
        _action = ""
        options.options = story.get_actions(_active, default_actions)
        options.selected = _action


func _update_input() -> void:
    if _action && _target:
        input_text.data = "%s%s %s " %  [input_prefix, _action, _target]
    elif _action:
        input_text.data = "%s%s " %  [input_prefix, _action]
    else:
        input_text.data = input_prefix
