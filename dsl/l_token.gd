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

func _add_descendant(descendant: LToken, take_descendants_place: bool = false) -> bool:
    if descendant == self:
        push_error("%s cannot have itself as descendant" % [self.info(true, 1)])
        return false

    if !_can_have_more_decendants(self):
        return false

    var parent: LToken = descendant._parent

    if parent && parent != self:
        parent._descendants.erase(descendant)

    descendant._parent = self
    _descendants.append(descendant)

    if take_descendants_place:
        if self._parent:
            self._parent._descendants.erase(self)
        parent._descendants.append(self)
        self._parent = parent

    return true

var value: Variant = "Token not evaluated"

var is_error: bool:
    get():
        return type == Type.ERROR
