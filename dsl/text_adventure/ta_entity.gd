extends RefCounted
class_name TAEntity

const _APPEND_TEXT = "_append_text"

var id: String:
    set(value):
        id = value
        if name == null:
            name = LToken.new(LToken.Type.LITERAL_STRING, value.split(":")[-1])

var name: LToken

var visits: int

var text_rule: LToken
var texts: Array[String]

var effect: LToken

# Not loaded from conf
var state: Dictionary

func _init(section: String) -> void:
    id = section

func set_appended_text(text: String) -> void:
    if text.is_empty():
        state.erase(_APPEND_TEXT)
    else:
        state[_APPEND_TEXT] = text

func get_appended_text() -> String:
    return state.get(_APPEND_TEXT, "")
