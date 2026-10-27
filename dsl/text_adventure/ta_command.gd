extends RefCounted
class_name TACommand

var _action: String
var _referent: String

var is_specific: bool:
    get():
        return !catch_all_action && !catch_all_referent

var catch_all_action: bool:
    get():
        return _action == "*"

var catch_all_referent: bool:
    get():
        return _referent == "*"

func _init(parts: Array) -> void:
    if parts.size() >= 2:
        _action = parts[0]
        _referent = parts[1]
    elif parts.size() == 1:
        _action = parts[0]
        _referent = "*"
    else:
        _action = "*"
        _referent = "*"

func matches(action: String, referent: String) -> bool:
    if _action != action && !catch_all_action:
        return false

    return _referent == referent || catch_all_referent


func _to_string() -> String:
    return "%s %s" % [_action, _referent]

func replace_referent(referent: String) -> TACommand:
    return TACommand.new([_action, referent])
