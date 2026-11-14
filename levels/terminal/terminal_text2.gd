extends RichTextLabel
class_name TerminalText2

const CURSOR_1: Array[String] = ["\\", "-", "/"]
const CURSOR_2: Array[String] = ["_", " "]
const CURSOR_3: Array[String] = [" ", "[bgcolor=%s] [/bgcolor]"]

signal text_event(evt_name: String)
signal text_done()
signal text_paused()

enum Phase { WAITING, ANIMATING }
enum _CmdParts { CLEAN_TEXT_START, DATA_END, CMD, VALUE, VALUE2 }
enum _Cmd { WAIT, SIGNAL, CURSOR, CLEAR, SPEED, MORE }

@export var autoplay: bool = true
@export var autoclear: bool = false

@export_multiline() var _data: String

@export var cursor_color: String = "blue"
@export var default_speed: float = 0.1
@export var default_cursor_speed: float = 0.4

var _clean_text: String
var _phase: Phase = Phase.WAITING
var _char_speed: float = 0.0
var _cursor_speed: float = 0.1
var _cursor_mode: int = 0
var _cursor_animation_idx: int = 0
var _next_cur_time: float = 0.0
var _total_visible_charcters: int
var _next_char_time: float = 0.0
var _commands: Array[Dictionary]
var _last_command_idx: int = -1
var _clean_text_idx: int = 0
var _char_step: int = 1
var _clean_text_start_idx: int = 0
var _clean_text_invisibles: Dictionary[int, int]
var _next_visible_characters: int

func is_anmating() -> bool:
    return _phase == Phase.ANIMATING

func is_instant() -> bool:
    return _char_speed == 0

func add_data(new_data: String) -> void:
    if autoclear:
        clear_text(new_data)
    else:
        _data += new_data

    _preprocess_data()

    if autoplay:
        play()

func set_data(new_data: String) -> void:
    clear_text()
    _data = new_data
    restore_default_speeds()
    _preprocess_data()
    if autoplay:
        play()

func has_data(other: String) -> bool:
    return _data == other

func clear_text(next_text: String = "") -> void:
    _last_command_idx = -1
    _total_visible_charcters = 0
    _clean_text_idx = 0
    _clean_text_start_idx = 0
    visible_characters = 0
    text = next_text
    _data = ""
    _char_step = 0

func restore_default_speeds() -> void:
    _char_speed = default_speed
    _cursor_speed = default_cursor_speed
    _next_char_time = default_speed

func fast_forward() -> void:
    _char_speed = 0
    _next_char_time = 0.0

func play() -> void:
    if _phase == Phase.ANIMATING:
        return

    _phase = Phase.ANIMATING
    _next_char_time = _char_speed
    _next_cur_time = _cursor_speed

func _preprocess_data() -> void:
    _commands.clear()
    var current_data_idx: int = 0
    var v_characters: int = 0
    var l: int = _data.length()
    var clean_text: String = ""

    while current_data_idx < l:
        var next_bb: int = _data.find("[", current_data_idx)
        var next_cmd: int = _data.find("{", current_data_idx)

        if next_bb < 0 && next_cmd < 0:
            v_characters += l - current_data_idx
            clean_text += _data.substr(current_data_idx)
            break

        elif next_cmd >= 0 && (next_bb < 0 || next_cmd < next_bb):
            var preceeding_text: int = next_cmd - current_data_idx
            var cmd: Dictionary[_CmdParts, Variant] = _parse_command(current_data_idx, clean_text.length(), preceeding_text)
            if _CmdParts.CMD not in cmd:
                current_data_idx += next_cmd
                v_characters += next_cmd
                continue


            if preceeding_text > 0:
                clean_text += _data.substr(current_data_idx, preceeding_text)
                v_characters += preceeding_text
            current_data_idx = cmd[_CmdParts.DATA_END]
            _commands.append(cmd)

        else:
            var closing: int = _data.find("]", current_data_idx)
            if closing > 0:
                var preceeding_text: int = next_bb - current_data_idx
                var length: int = closing - next_bb + 1
                _clean_text_invisibles[clean_text.length() + preceeding_text] = length
                clean_text += _data.substr(current_data_idx, length + preceeding_text)
                v_characters += preceeding_text
                current_data_idx += length + preceeding_text

            else:
                clean_text += _data[current_data_idx]
                current_data_idx += next_bb
                v_characters += next_bb

    _clean_text = clean_text
    if visible_characters < 0:
        visible_characters = 0

    _total_visible_charcters = v_characters
    text = clean_text


func _parse_command(current_data_idx: int, clean_text: int, preceeding_text: int) -> Dictionary[_CmdParts, Variant]:
    var start: int = clean_text + preceeding_text
    for inv: int in _clean_text_invisibles:
        if start - _clean_text_invisibles[inv] == inv:
            start -= _clean_text_invisibles[inv]

    var parsed: Dictionary[_CmdParts, Variant] = { _CmdParts.CLEAN_TEXT_START: start }
    var closing: int = _data.find("}", current_data_idx)
    if closing < 0:
        return parsed

    var length = closing - (current_data_idx + preceeding_text)
    var command: String = _data.substr(current_data_idx + preceeding_text, length)
    command = command.trim_prefix("{").trim_suffix("}")
    parsed[_CmdParts.DATA_END] = current_data_idx + preceeding_text + length + 1

    var cmd = command.to_upper().split(" ", true, 1)[0]

    match cmd:
        "WAIT":
            var parts: PackedStringArray = command.split(" ")
            var time = 0.0
            if parts.size() > 1:
                time = float(parts[1])
            if time == 0.0:
                time = default_speed

            parsed[_CmdParts.CMD] = _Cmd.WAIT
            parsed[_CmdParts.VALUE] = time
            return parsed

        "SIGNAL":
            var parts: PackedStringArray = command.split(" ", true, 1)
            if parts.size() > 1:
                parsed[_CmdParts.VALUE] = parts[1]
            else:
                parsed[_CmdParts.VALUE] = ""

            parsed[_CmdParts.CMD] = _Cmd.SIGNAL
            return parsed

        "CURSOR":
            var parts: PackedStringArray = command.split(" ")
            if parts.size() == 1:
                parsed[_CmdParts.VALUE] = 1
            else:
                parsed[_CmdParts.VALUE] = int(parts[1])
                if parts.size() > 2:
                    parsed[_CmdParts.VALUE2] = float(parts[2])
                parsed[_CmdParts.CMD] = _Cmd.CURSOR
                return parsed

        "CLEAR":
            parsed[_CmdParts.CMD] = _Cmd.CLEAR
            parsed[_CmdParts.VALUE] = clean_text + preceeding_text
            return parsed

        "SPEED":
            var parts: PackedStringArray = command.split(" ")
            if parts.size() > 1:
                var time: float = float(parts[1])
                if time < 0:
                    time = default_speed
                parsed[_CmdParts.VALUE] = time
                parsed[_CmdParts.CMD] = _Cmd.SPEED
                return parsed

            else:
                push_error("Char speed must have float")
                return parsed

        "MORE":
            parsed[_CmdParts.CMD] = _Cmd.MORE
            return parsed

    push_error("Unknown command ", command)
    return parsed


func _ready() -> void:
    if visible_characters_behavior == TextServer.VisibleCharactersBehavior.VC_CHARS_BEFORE_SHAPING:
        push_warning("Consider updating visible characters behavior to after shaping to make reveal nicer")

    if !_data.is_empty():
        _preprocess_data()

    restore_default_speeds()

    if autoplay:
        play()

func _process(delta: float) -> void:
    if _phase != Phase.ANIMATING:
        return

    _next_cur_time -= delta
    _next_char_time -= delta

    while _next_char_time < 0:
        if _char_step > 0:
            _clean_text_idx += _char_step + _clean_text_invisibles.get(_clean_text_idx, 0)
            _next_char_time += _char_speed
            _next_visible_characters += 1

        _char_step = _exec_commands()
        if _char_step < 0 || _next_visible_characters > _total_visible_charcters:
            if _next_visible_characters > _total_visible_charcters:
                text_done.emit()
                _phase = Phase.WAITING
            break

    if _cursor_mode == 0:
        _next_cur_time = 0
        visible_characters = _next_visible_characters
        return

    if _next_cur_time <= 0:
        _cursor_animation_idx += 1
        _next_cur_time = _cursor_speed

    text = _clean_text.substr(_clean_text_start_idx, _clean_text_idx - _clean_text_start_idx) + _get_cursor_char()
    visible_characters = -1

func _get_cursor_char() ->  String:
    if _cursor_mode == 1:
        return CURSOR_1[posmod(_cursor_animation_idx, CURSOR_1.size())]
    if _cursor_mode == 2:
        return CURSOR_2[posmod(_cursor_animation_idx, CURSOR_2.size())]
    if _cursor_mode == 3:
        var cur: String = CURSOR_3[posmod(_cursor_animation_idx, CURSOR_3.size())]
        if cur.contains("%s"):
            return cur % cursor_color
        return cur

    return ""

func _exec_commands() -> int:
    for cid: int in range(_last_command_idx + 1, _commands.size()):
        var cmd: Dictionary = _commands[cid]
        if cmd[_CmdParts.CLEAN_TEXT_START] < _clean_text_idx:
            push_error("Failed to execute %s, never encountered start index (current %s)" % [cmd, _clean_text_idx])
            _last_command_idx = cid
            continue

        if cmd[_CmdParts.CLEAN_TEXT_START] != _clean_text_idx:
            return 1

        _last_command_idx = cid

        match cmd[_CmdParts.CMD]:
            _Cmd.WAIT:
                _next_char_time += cmd[_CmdParts.VALUE]
                return -1

            _Cmd.SIGNAL:
                text_event.emit(cmd[_CmdParts.VALUE])
                return 0

            _Cmd.CURSOR:
                var mode: int = cmd[_CmdParts.VALUE]
                if mode >= 0:
                    if _cursor_mode != mode:
                        if mode == 0:
                            text = _clean_text.substr(_clean_text_start_idx)
                        else:
                            _cursor_animation_idx = 0

                    _cursor_mode = mode

                var speed: float = cmd.get(_CmdParts.VALUE2, -1)
                if speed >= 0:
                    _cursor_speed = speed

                return 0

            _Cmd.CLEAR:
                _clean_text_start_idx = cmd[_CmdParts.VALUE]
                _next_visible_characters = 0
                if _cursor_mode == 0:
                    text = _clean_text.substr(_clean_text_start_idx)
                return 0

            _Cmd.SPEED:
                _char_speed = cmd[_CmdParts.VALUE]
                return 0

            _Cmd.MORE:
                _phase = Phase.WAITING
                text_paused.emit()
                return -1

    return 1
