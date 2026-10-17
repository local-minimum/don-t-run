extends RichTextLabel
class_name TerminalText

signal text_event(evt_name: String)
signal text_done()

@export var autoplay: bool = true
@export var autoclear: bool = false
@export var select_color: String = "blue"

@export_multiline() var data: String:
    set(value):
        if autoclear:
            text = ""
        _char_speed = default_speed
        _cursor_speed = default_cursor_speed
        data = value
        if autoplay:
            play()

@export var default_speed: float = 0.04
@export var default_cursor_speed: float = 0.07

const CURSOR_1: Array[String] = ["\\", "-", "/"]
const CURSOR_2: Array[String] = ["_", " "]
const CURSOR_3: Array[String] = ["_", "[bgcolor=%s]x[/bgcolor]"]

var _current_data_idx: int = 0
var _playing = false
var _char_speed: float = 0.0
var _next_char: float = 0.0

func _ready() -> void:
    _char_speed = default_speed
    _cursor_speed = default_cursor_speed
    if !autoplay:
        set_process(false)

func play() -> void:
    _playing = true
    _next_char = default_speed
    set_process(true)

func _process_command() -> bool:
    var closing: int = data.find("}", _current_data_idx)
    if closing < 0:
        return true

    var length = closing - _current_data_idx
    var command: String = data.substr(_current_data_idx, length)
    command = command.trim_prefix("{").trim_suffix("}")
    _current_data_idx += length + 1

    if command.begins_with("WAIT"):
        var parts: PackedStringArray = command.split(" ")
        var time = 0.0
        if parts.size() > 1:
            time = float(parts[1])
        if time == 0.0:
            time = default_speed
        _next_char += time
        return false

    elif command.begins_with("SIGNAL"):
        var parts: PackedStringArray = command.split(" ", true, 1)
        if parts.size() > 1:
            text_event.emit(parts[1])
        else:
            text_event.emit("")

    elif command.begins_with("CURSOR"):
        var parts: PackedStringArray = command.split(" ")
        if parts.size() == 1:
            _change_cursor(1)
        else:
            var mode: int = int(parts[1])
            if parts.size() > 2:
                _cursor_speed = float(parts[2])
            _change_cursor(mode)

    elif command.begins_with("CLEAR"):
        text = ""

    elif command.begins_with("SPEED"):
        var parts: PackedStringArray = command.split(" ")
        if parts.size() > 1:
            var time: float = float(parts[1])
            _char_speed = time
            _next_char = _char_speed
        else:
            push_error("Char speed must have float")

    else:
        push_error("Unknown command", command)
    return true

var _cursor_speed: float = 0.1
var _cursor_mode: int = 0
var _cursor_idx: int = 0
var _next_cur: float = 0.0

var _cursor_char: String:
    get():
        if _cursor_mode == 1:
            return CURSOR_1[posmod(_cursor_idx, CURSOR_1.size())]
        if _cursor_mode == 2:
            return CURSOR_2[posmod(_cursor_idx, CURSOR_2.size())]
        if _cursor_mode == 3:
            var cur: String =  CURSOR_3[posmod(_cursor_mode, CURSOR_3.size())]
            if cur.contains("%s"):
                return cur % select_color
            return cur
        return ""

func _strip_cursor() -> void:
    if _cursor_mode != 0:
        var cur: String = _cursor_char
        if text.ends_with(cur):
            text = text.trim_suffix(cur)

func _change_cursor(mode: int = - 1, delta: float = 0.0, strip: bool = true) -> void:
    _next_cur -= delta
    if (mode == -1 || mode == _cursor_mode) && _next_cur > 0.0:
        return

    if strip:
        _strip_cursor()

    if mode >=0 && mode != _cursor_mode:
        _cursor_mode = mode
        _cursor_idx = 0

    _next_cur += _cursor_speed
    _cursor_idx += 1
    text += _cursor_char

func _process(delta: float) -> void:
    _next_char -= delta
    if !_playing || _next_char > 0.0:
        _change_cursor(-1, delta)
        return

    _strip_cursor()

    _next_char += _char_speed
    while _process_next():
        pass

    _change_cursor(-1, delta, false)

func _process_next() -> bool:
    if _current_data_idx >= data.length():
        if _cursor_mode == 0:
            set_process(false)
        text_done.emit()
        _playing = false
        return false

    match data.substr(_current_data_idx, 1):
        "[":
            var closing: int = data.find("]", _current_data_idx)
            if closing > 0:
                var length = closing - _current_data_idx
                text += data.substr(_current_data_idx, length)
                _current_data_idx += length
                return true
        "{":
            if !_process_command():
                return false

    if _current_data_idx >= data.length():
        if _cursor_mode == 0:
            set_process(false)
        text_done.emit()
        _playing = false
        return false

    if "{[".contains(data[_current_data_idx]):
        return true

    text += data[_current_data_idx]
    _current_data_idx += 1
    return _char_speed <= 0.0
