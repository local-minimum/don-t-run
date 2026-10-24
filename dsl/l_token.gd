extends RefCounted
class_name LToken


enum Type { STATEMENT, ERROR, FUNCTION, PARAMETER, LITERAL_STRING, LITERAL_INT, LITERAL_BOOL, LITERAL_FLOAT, OP_NOT, OP_AND, OP_OR, PARENTHESIS }

func _init(_type: Type = Type.STATEMENT, data: String = "") -> void:
    self.type = _type
    self._data = data

var _data: String
var type: Type = Type.STATEMENT
var _parent: LToken
var _descendants: Array[LToken]

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

var value: Variant = "Token not evaluated"

var is_error: bool:
    get():
        return type == Type.ERROR
