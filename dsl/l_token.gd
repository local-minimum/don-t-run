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



func parse(text: String) -> void:
    if _parent || type != Type.STATEMENT && type != Type.ERROR:
        type = Type.ERROR
        value = "Can only parse root statements"
        return

    type = Type.STATEMENT
    value = null
    _parent = null
    _descendants.clear()

    var word_pattern: RegEx = RegEx.new()
    word_pattern.compile("[a-zA-Z-_0-9]+")
    var function_name: RegEx = RegEx.new()
    function_name.compile("^[a-zA-Z_0-9]+$")

    var words: Array[RegExMatch] = word_pattern.search_all(text)

    var parenthesis_stack: Array[LToken]
    var in_string_litteral: bool
    var word_idx: int = 0
    var n_words: int = words.size()
    var char_buffer: String = ""
    var active: LToken = self
    var text_len: int = text.length()
    var idx: int = 0

    while idx < text_len:
        if word_idx < n_words && idx == words[word_idx].get_start():
            var word: String = words[word_idx].get_string()
            char_buffer += word
            word_idx += 1
            idx += word.length()
            continue

        else:
            if in_string_litteral:
                var p_letter: String = "" if char_buffer.is_empty() else char_buffer[char_buffer.length() -1]
                var letter: String = text[idx]
                if letter == "\"" && p_letter != "\\":
                    in_string_litteral = false
                    if !_can_have_more_decendants(active):
                        type = Type.ERROR
                        value = "%s cannot have string literal '%s' at %s" % [active.info(), char_buffer, idx]
                        return

                    var d: LToken = LToken.new(Type.LITERAL_STRING, char_buffer)
                    if !active._add_descendant(d):
                        type = Type.ERROR
                        value = "%s cannot take string literal '%s' at '%s'" % [active.info(true, 1), char_buffer, idx]

                    active = d
                    char_buffer = ""
                elif letter == "\"" && p_letter == "\\":
                    char_buffer = char_buffer.trim_suffix("\\") + letter
                else:
                    char_buffer += text[idx]

                idx += 1
                continue

            match text[idx]:
                " ":
                    if !char_buffer.is_empty() && "&|".contains(char_buffer[char_buffer.length() - 1]):
                        type = Type.ERROR
                        value = "Only && and || operands supported at %s" % [idx]
                        return

                    char_buffer += " "

                ",":
                    char_buffer = char_buffer.strip_edges()
                    if active.type == Type.FUNCTION:
                        if char_buffer.is_empty():
                            type = Type.ERROR
                            value = "Function has empty parameter at %s" % idx
                            return

                        var dtype: Type = _char_buffer_disambiguation(char_buffer)
                        if dtype == Type.ERROR:
                            type = Type.ERROR
                            value = "Invalid parameter or literal to function at %s" % idx
                            return

                        if !active._add_descendant(LToken.new(dtype, char_buffer)):
                            type = Type.ERROR
                            value = "Failed to add '%s' to %s at %s" % [char_buffer, active.info(true, 1), idx]
                            return

                        char_buffer = ""
                    else:
                        if !char_buffer.is_empty():
                            if !_can_have_more_decendants(active):
                                type = Type.ERROR
                                value = "Attempting to add too many decendants to %s at %s" % [Type.find_key(active.type), idx]
                                return

                        var dtype: Type = _char_buffer_disambiguation(char_buffer)
                        if dtype == Type.ERROR:
                            type = Type.ERROR
                            value = "Invalid parameter or literal at %s" % idx
                            return

                        if !active._add_descendant(LToken.new(dtype, char_buffer)):
                            type = Type.ERROR
                            value = "Failed to add '%s' to %s at %s" % [char_buffer, active.info(true, 1), idx]
                            return

                        while active != null && active.type != Type.FUNCTION:
                            active = active._parent

                        if active == null:
                            type = Type.ERROR
                            value = "Listing only allowed for function parameters, position %s not inside function" % [idx]
                            return

                "(":
                    char_buffer = char_buffer.strip_edges()
                    if char_buffer.is_empty():
                        if !_can_have_more_decendants(active):
                            type = Type.ERROR
                            value = "%s cannot have a parenthesis at %s" % [Type.find_key(active.type), idx]
                            return

                        var par: LToken = LToken.new(Type.PARENTHESIS)
                        if !active._add_descendant(par):
                            type = Type.ERROR
                            value = "Cannot add %s to %s at %s" % [par.info(), active.info(true, 1), idx]
                            return

                        active = par
                        parenthesis_stack.append(par)

                    elif function_name.search(char_buffer) != null:
                        if !_can_have_more_decendants(active):
                            type = Type.ERROR
                            value = "%s cannot have a function '%s' decendant at %s" % [Type.find_key(active.type), char_buffer, idx]
                            return

                        var fn: LToken = LToken.new(Type.FUNCTION, char_buffer)

                        if !active._add_descendant(fn):
                            type = Type.ERROR
                            value = "%s cannot be added to %s at %s" % [fn.info(), active.info(true, 1), idx]
                            return

                        active = fn
                        parenthesis_stack.append(fn)
                        char_buffer = ""
                    else:
                        type = Type.ERROR
                        value = "Illegal function name '%s' at %s" % [char_buffer, idx]
                        return

                ")":
                    char_buffer = char_buffer.strip_edges()
                    if !char_buffer.is_empty():
                        if !_can_have_more_decendants(active):
                            type = Type.ERROR
                            value = "%s cannot have '%s' decendant at %s" % [active.info(), char_buffer, idx]
                            return

                        var dtype: Type = _char_buffer_disambiguation(char_buffer)
                        if dtype == Type.ERROR:
                            type = Type.ERROR
                            value = "Invalid type at %s" % [idx]
                            return

                        var child: LToken = LToken.new(dtype, char_buffer)
                        if !active._add_descendant(child):
                            type = Type.ERROR
                            value = "%s cannot be added to %s at %s" % [child.info(), active.info(true, 1), idx]
                            return

                    if parenthesis_stack.is_empty():
                        type = Type.ERROR
                        value = "Unmatched right side parenthesis at %s" % idx
                        return

                    var closed: LToken = parenthesis_stack.pop_back()
                    while active != closed:
                        active = active._parent
                        if active == null:
                            type = Type.ERROR
                            value = "Failed to find %s by closing parenthesis at %s" % [closed.info(), idx]

                    if !_is_complete(active):
                        type = Type.ERROR
                        value = "%s is incomplete at %s" % [active.info(), idx]
                        return

                    char_buffer = ""

                "!":
                    char_buffer = char_buffer.strip_edges()
                    if !char_buffer.is_empty():
                        type = Type.ERROR
                        value = "! cannot follow '%s' at position %s" % [char_buffer, idx]
                        return
                    elif !_can_have_more_decendants(active):
                        type = Type.ERROR
                        value = "! cannot be decendent of a %s at postion %s" % [Type.find_key(active._parent.type), idx]
                        return
                    else:

                        var d: LToken = LToken.new(Type.OP_NOT)
                        active._add_descendant(d)
                        active = d

                "&":
                    if !char_buffer.is_empty() && char_buffer[char_buffer.length() - 1] == "&":
                        char_buffer = char_buffer.trim_suffix("&").strip_edges()

                        var d: LToken = LToken.new(Type.OP_AND)
                        active = _add_left_side(d, active, char_buffer, parenthesis_stack)
                        if active == null:
                            type = Type.ERROR
                            value = "Not a valid left side of && at %s" % idx
                            return

                        char_buffer = ""
                    elif char_buffer.is_empty():
                        type = Type.ERROR
                        value = "Operator at %s requires a left side %s" % idx
                        return
                    elif char_buffer.contains("|"):
                        type = Type.ERROR
                        value = "Jumbled operator at %s" % idx
                        return
                    else:
                        char_buffer += "&"

                "|":
                    if !char_buffer.is_empty() && char_buffer[char_buffer.length() - 1] == "|":
                        char_buffer = char_buffer.trim_suffix("|").strip_edges()

                        var d: LToken = LToken.new(Type.OP_OR)
                        active = _add_left_side(d, active, char_buffer, parenthesis_stack)
                        if active == null:
                            type = Type.ERROR
                            value = "Not a valid left side of || at %s" % idx
                            return

                        char_buffer = ""
                    elif char_buffer.is_empty():
                        type = Type.ERROR
                        value = "Operator at %s requires a left side %s" % idx
                        return
                    elif char_buffer.contains("|"):
                        type = Type.ERROR
                        value = "Jumbled operator at %s" % idx
                        return
                    else:
                        char_buffer += "|"

                "\"":
                    if in_string_litteral:
                        in_string_litteral = false
                        if !_can_have_more_decendants(active):
                            type = Type.ERROR
                            value = "%s cannot take string '%s' at %s" % [active.info(), char_buffer, idx]
                            return

                        var d: LToken = LToken.new(Type.LITERAL_STRING, char_buffer)
                        if !active._add_descendant(d):
                            type = Type.ERROR
                            value = "Could not add descendant %s to %s" % [d.info(), active.info(true, 1)]
                            return
                        active = d
                        char_buffer = ""
                    else:
                        char_buffer = char_buffer.strip_edges()
                        if !char_buffer.is_empty():
                            type = Type.ERROR
                            value = "String literal cannot follow '%s' at %s" % [char_buffer, idx]
                            return

                        in_string_litteral = true
                ".":
                    char_buffer += "."
                ":":
                    char_buffer += ":"
                _:
                    type = Type.ERROR
                    value = "Illegal character '%s' at %s" % [text[idx], idx]
                    return

            idx += 1
            continue

    char_buffer = char_buffer.strip_edges()
    if !char_buffer.is_empty():
        if !_can_have_more_decendants(active):
            type = Type.ERROR
            value = "%s doesn't allow more decendants but had remaining '%s'" % [active.info(true), char_buffer]
            return

        var dtype: Type = _char_buffer_disambiguation(char_buffer)
        if dtype == Type.ERROR:
            type = Type.ERROR
            value = "Invalid remaining parameter or literal '%s'" % [char_buffer]
            return

        var child: LToken = LToken.new(dtype, char_buffer)
        if !active._add_descendant(child):
            type = Type.ERROR
            value = "Could not add descendant %s to %s" % [child.info(), active.info(true, 1)]
            return

    if !_is_complete(self):
        type = Type.ERROR
        value = "%s is not complete" % active.info(true)
        return

    if !parenthesis_stack.is_empty():
        type = Type.ERROR
        value = "%s isn't closed" % parenthesis_stack[parenthesis_stack.size() - 1].info(true)
        return


static func _add_left_side(new_token: LToken, active: LToken, char_buffer: String, open: Array[LToken]) -> LToken:
    if active == null:
        return null

    if !char_buffer.is_empty():
        char_buffer = char_buffer.strip_edges()

    var dtype: Type
    if active.type == Type.FUNCTION:
        if open.has(active) != char_buffer.is_empty():
            return null

        if open.has(active):
            dtype = _char_buffer_disambiguation(char_buffer)
            if dtype == Type.ERROR:
                return null

            if !_can_have_more_decendants(active) || !_can_have_more_decendants(new_token):
                return null

            var child: LToken = LToken.new(dtype, char_buffer)
            if !new_token._add_descendant(child) || !active._add_descendant(new_token):
                return null

            return new_token

        if !_can_have_more_decendants(new_token):
            return null

        var par: LToken = active._parent
        while par.type == Type.OP_AND && new_token.type == Type.OP_OR:
            par = par._parent
            if par == null:
                return null

        var a: LToken = par._descendants.pop_back()
        if a != active && a.type != Type.OP_AND:
            return null

        if !par._add_descendant(new_token) || !new_token._add_descendant(a):
            return null

        return new_token

    elif active.type == Type.OP_NOT:
        if active._parent == null:
            return null

        if char_buffer.is_empty() && !_is_complete(active):
            return null

        dtype = _char_buffer_disambiguation(char_buffer)
        if dtype == Type.ERROR:
            return null

        if !_can_have_more_decendants(active) || !_can_have_more_decendants(new_token):
            return null

        var child: LToken = LToken.new(dtype, char_buffer)
        if !active._add_descendant(child):
            return null

        var par: LToken = active._parent
        while par.type == Type.OP_AND && new_token.type == Type.OP_OR:
            par = par._parent
            if par == null:
                return null

        var a: LToken = par._descendants.pop_back()
        if a != active && a.type != Type.OP_AND:
            return null

        if !par._add_descendant(new_token) || !new_token._add_descendant(a):
            return null

        return new_token

    elif [Type.LITERAL_STRING, Type.LITERAL_INT, Type.LITERAL_BOOL, Type.LITERAL_FLOAT].has(active.type):
        if !char_buffer.is_empty():
            return null

        var par: LToken = active._parent
        if par == null:
            return null

        while par.type == Type.OP_AND && new_token.type == Type.OP_OR:
            par = par._parent

            if par == null:
                return null

        var child: LToken = par._descendants.pop_back()
        if child == null:
            return

        if !new_token._add_descendant(child) || !par._add_descendant(new_token):
            return null

        return new_token

    elif active.type == Type.OP_OR || new_token.type == Type.OP_AND:
        if char_buffer.is_empty():
            return null

        if !_can_have_more_decendants(active) || !_can_have_more_decendants(new_token):
            return null

        dtype = _char_buffer_disambiguation(char_buffer)
        if dtype == Type.ERROR:
            return null

        var child: LToken = LToken.new(dtype, char_buffer)
        if !new_token._add_descendant(child) || !active._add_descendant(new_token):
            return null

        return new_token

    if char_buffer.is_empty():
        return null

    var need_shuffle: bool
    while active.type == Type.OP_AND:
        if active._descendants.size() != 1:
            return null

        if active._parent == null:
            return null

        need_shuffle = true
        active = active._parent

    if need_shuffle:
        if active._descendants.is_empty():
            return null

        if !_can_have_more_decendants(new_token):
            return null

        var child: LToken = active._descendants.pop_back()
        if child.type != Type.OP_AND && child._descendants.size() != 1:
            return null

        dtype = _char_buffer_disambiguation(char_buffer)
        if dtype == Type.ERROR:
            return null

        if !child._add_descendant(LToken.new(dtype, char_buffer)) || !new_token._add_descendant(child) || !active._add_descendant(new_token):
            return null

        return new_token

    if !_can_have_more_decendants(new_token) || !_can_have_more_decendants(active):
        return null

    dtype = _char_buffer_disambiguation(char_buffer)
    if dtype == Type.ERROR:
        return null

    if !new_token._add_descendant(LToken.new(dtype, char_buffer)) || !active._add_descendant(new_token):
        return null

    return new_token

static func _char_buffer_disambiguation(char_buffer: String) -> Type:
    if char_buffer == "true" || char_buffer == "false":
        return Type.LITERAL_BOOL

    var all_num: RegEx = RegEx.new()
    all_num.compile("^[0-9]+$")
    if all_num.search(char_buffer) != null:
        return Type.LITERAL_INT

    var float_pattern: RegEx = RegEx.new()
    float_pattern.compile("^[0-9]*\\.[0-9]*$")
    if char_buffer != "." && float_pattern.search(char_buffer) != null:
        return Type.LITERAL_FLOAT

    if char_buffer.contains("&") || char_buffer.contains("|") || char_buffer.contains("!"):
        return Type.ERROR

    return Type.PARAMETER

static func _in_function(active: LToken) -> bool:
    while active && active.type != Type.FUNCTION:
        active = active._parent

    return active != null

static func _is_complete(t: LToken) -> bool:
    if t == null:
        return false

    var n: int = t._descendants.size()

    match t.type:
        Type.STATEMENT:
            return n < 2
        Type.ERROR:
            return !t.value.is_empty()
        Type.FUNCTION:
            return true
        Type.PARAMETER:
            return n == 0 && !t._data.is_empty()
        Type.LITERAL_STRING:
            return n == 0
        Type.LITERAL_INT:
            return n == 0 && !t._data.is_empty()
        Type.LITERAL_BOOL:
            return n == 0 && !t._data.is_empty()
        Type.LITERAL_FLOAT:
            return n == 0 && !t._data.is_empty()
        Type.OP_NOT:
            return n == 1
        Type.OP_AND:
            return n == 2
        Type.OP_OR:
            return n == 2
        Type.PARENTHESIS:
            return n == 1
        _:
            return false

static func _can_have_more_decendants(t: LToken) -> bool:
    if t == null:
        return false

    var n: int = t._descendants.size()

    match t.type:
        Type.STATEMENT, Type.OP_NOT, Type.PARENTHESIS:
            return n == 0
        Type.FUNCTION:
            return true
        Type.PARAMETER, Type.LITERAL_STRING, Type.LITERAL_INT, Type.LITERAL_BOOL, Type.LITERAL_FLOAT:
            return false
        Type.OP_AND, Type.OP_OR:
            return n < 2
        _:
            return false


var value: Variant = "Token not evaluated"

var is_error: bool:
    get():
        return type == Type.ERROR
