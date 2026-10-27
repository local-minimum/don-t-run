extends RefCounted
class_name LToken


enum Type { STATEMENT, ERROR, FUNCTION, PARAMETER, LITERAL_STRING, LITERAL_INT, LITERAL_BOOL, LITERAL_FLOAT, OP_NOT, OP_AND, OP_OR, PARENTHESIS }

func _init(_type: Type = Type.STATEMENT, data: String = "") -> void:
    self.type = _type
    self._data = data
    match _type:
        Type.LITERAL_STRING:
            value = data
        Type.LITERAL_INT:
            value = int(data)
        Type.LITERAL_BOOL:
            value = data != "false"
        Type.LITERAL_FLOAT:
            value = float(data)

var _data: String
var type: Type = Type.STATEMENT
var _parent: LToken
var _descendants: Array[LToken]
var value: Variant = null

var is_error: bool:
    get():
        return type == Type.ERROR

var is_parameter: bool:
    get():
        return type == Type.PARAMETER

var is_function: bool:
    get():
        return type == Type.FUNCTION

var function_name: String:
    get():
        if type != Type.FUNCTION:
            return ""
        return _data

var parameter_name: String:
    get():
        if type != Type.PARAMETER:
            return ""
        return _data

func get_parent_function() -> LToken:
    var p: LToken = _parent
    while p != null:
        if p.type == Type.FUNCTION:
            return p

        p = p._parent

    return null


func info(recursive: bool = false, depth: int = 100) -> String:
    if depth < 0:
        return "[!TOO DEEP]"

    var ret: String = "[%s%s" % [Type.find_key(type), "" if _data.is_empty() else " %s" % _data]
    if type == Type.ERROR:
        return ret + (": \"%s\"]" % value)

    if recursive:
        if _descendants.is_empty():
            return ret + "]"

        ret += ": "
        var first: bool = true
        for child: LToken in _descendants:
            if !first:
                ret += ", "
            ret += child.info(true, depth - 1)

            first = false

    return ret + "]"
