extends Control
class_name TATerminal

enum Phase { INACTIVE, ACTION, REFERANT, COMMIT, MORE }

signal text_event(evt: String)

@export var stories: Array[TAStory]
@export var main_text: TerminalText2
@export var input_text: TerminalText2
@export var options: OptionsPresenter
@export var input_prefix: String = "> "
@export var input_cursor: TerminalText2.Cursor = TerminalText2.Cursor.UNDERLINE
@export var more_option: String = "MORE"
@export var default_actions: Array[String] = []
@export var delay_show_command: float = 0.75
@export var autoplay_story: String
@export var delay_play_initial_story: float = 0.5

@export var _music_players: Array[AudioStreamPlayer]
@export var _dialog_player: AudioStreamPlayer
@export var interactive = true:
    set(value):
        if input_text:
            input_text.visible = value
        if options:
            options.visible = value
        interactive = value

        if !value && options && options.active:
            options.active = false

        if value && input_text:
            _update_input()

var _active_story: TAStory
var _active: TAEntity
var _phase: Phase
var _action: String
var _target: String

func _enter_tree() -> void:
    main_text.text_done.connect(_handle_main_text_done)
    main_text.text_paused.connect(_handle_more)
    main_text.text_event.connect(_handle_main_text_event)
    input_text.text_done.connect(_handle_input_text_done)
    options.select_option.connect(_handle_update_option)
    options.abort_option.connect(_handle_abort_option)

func load_story(id: String = "", play_on_loaded: bool = true, delay_play: float = 0.0) -> void:
    if _active_story:
        if _active_story.story_loaded.is_connected(_handle_story_ready):
            _active_story.story_loaded.disconnect(set_anchor_and_offset)
        if _active_story.executed.is_connected(_handle_execute_entity):
            _active_story.executed.disconnect(_handle_execute_entity)

    _active_story = null
    _active = null
    _phase = Phase.INACTIVE

    for story: TAStory in stories:
        if story.story_id == id:
            _active_story = story
            break

    if _active_story == null:
        push_error("%s found no story with id '%s'" % [name, id])
        return

    _active_story.executed.connect(_handle_execute_entity)
    if play_on_loaded:
        if _active_story.is_loaded():
            _handle_story_ready(delay_play)
        else:
            _active_story.story_loaded.connect(_handle_story_ready.bind(delay_play), CONNECT_ONE_SHOT)
            _active_story.load_story()

func _ready() -> void:
    interactive = interactive

    if interactive:
        _update_input()

    if !autoplay_story.is_empty():
        load_story.call_deferred(autoplay_story, true, delay_play_initial_story)

func _input(event: InputEvent) -> void:
    if !interactive || options.active:
        return

    if event.is_action_pressed("select_option") && main_text.is_anmating():
        main_text.fast_forward()
        get_viewport().set_input_as_handled()

func _handle_main_text_event(evt: String) -> void:
    text_event.emit(evt)

func _handle_execute_entity(entity: TAEntity, body: String, title: String, force_append: bool) -> void:
    _phase = Phase.INACTIVE
    _active = entity
    var instant: bool = entity is TANode && main_text.is_instant()

    if !force_append && (entity is TAEdge || entity == null):
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

func _handle_story_ready(delay_play: float = 0.0) -> void:
    if delay_play > 0:
        await get_tree().create_timer(delay_play).timeout
    _active_story.exec_active_node()

func _handle_main_text_done() -> void:
    if _active is TAEdge || _active == null:
        if _active_story != null:
            if _active != null:
                _active_story.execute_edge_target(_active)
            _active_story.exec_active_node()

    elif _active is TANode:
        _phase = Phase.ACTION
        if interactive:
            _set_actions_options()

            input_text.show_cursor(input_cursor)
            if !input_text.has_data(input_prefix):
                input_text.fast_forward()
                input_text.set_data(input_prefix)

func _handle_input_text_done() -> void:
    if !interactive:
        return

    if _phase == Phase.INACTIVE:
        if input_text.has_cursor():
            input_text.remove_cursor()

            await get_tree().create_timer(delay_show_command).timeout

            if _phase == Phase.INACTIVE:
                if !input_text.has_data(input_prefix):
                    input_text.set_data(input_prefix)
    else:
        input_text.restore_default_speeds()
        input_text.show_cursor(input_cursor)

func _handle_update_option(value: String) -> void:
    if !interactive:
        push_warning("Ignoring options value '%s' because terminal not interactive" % [value])
        return

    match _phase:
        Phase.MORE:
            _phase = Phase.INACTIVE
            main_text.play()
            options.options = []
            options.active = false
            input_text.add_data("%s " % value)

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
            _active_story.execute_edge_by_command.call_deferred(_action, _target)
            _update_input()
            _action = ""
            _target = ""


func _handle_abort_option() -> void:
    if !interactive:
        push_error("Ignoring abort option because terminal not interactive")
        return

    if _phase == Phase.REFERANT:
        _phase = Phase.ACTION
        _set_actions_options()
        input_text.set_data(input_prefix)

func _set_actions_options() -> void:
    options.options = _active_story.get_actions(_active, default_actions)
    options.selected = _action
    options.active = true


func _set_referents_options() -> void:
    options.options = _active_story.get_referents(_active)
    options.selected = _target
    options.active = true

func _update_input() -> void:
    if !interactive:
        push_warning("Ignoring update input because terminal not interactive")
        return

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
    if !interactive:
        push_warning("Ignoring more because terminal not interactive")
        return

    _phase = Phase.MORE
    options.options = [more_option]
    options.active = true
    input_text.show_cursor(input_cursor)

#region Audio
var _fader: Tween

func play_music(stream: AudioStream, cross_fade: float = 1.0) -> void:
    if _fader && _fader.is_running():
        _fader.kill()

    var play_on: int = 1 if _music_players[0].playing else 0
    if cross_fade == 0:
        _music_players[(play_on + 1) % 2].stop()
        _music_players[play_on].stream = stream
        _music_players[play_on].play()
    else:
        _fader = create_tween()
        var new: AudioStreamPlayer = _music_players[play_on]
        var old: AudioStreamPlayer = _music_players[(play_on + 1) % 2]
        new.volume_linear = 0
        new.stream = stream
        new.play()
        _fader.tween_property(new, "volume_linear", 1.0, cross_fade)
        _fader.tween_property(old, "volume_linear", 0.0, cross_fade)
        _fader.finished.connect(
            func () -> void:
                old.stop()
                ,
        )

func play_dialog(stream: AudioStream) -> void:
    _dialog_player.stop()
    _dialog_player.stream = stream
    _dialog_player.play()
#endregion Audio
