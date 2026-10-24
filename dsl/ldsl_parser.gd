class_name LDSL_Parser

static func _add_left_side(new_token: LToken, active: LToken, char_buffer: String, open: Array[LToken]) -> LToken:
    if active == null:
        return null

    if !char_buffer.is_empty():
        char_buffer = char_buffer.strip_edges()

    var dtype: LToken.Type = _char_buffer_disambiguation(char_buffer)
    var child: LToken = LToken.new(dtype, char_buffer) if dtype != LToken.Type.ERROR else null

    if active.type == LToken.Type.FUNCTION:
        if open.has(active) == char_buffer.is_empty():
            return null

        if open.has(active):
            if child == null:
                return null

            if !_add_descendant(new_token, child) || !_add_descendant(active, new_token):
                return null

            return new_token

        if !_can_have_more_decendants(new_token):
            return null

        return _insert_operator_in_tree(active, new_token)

    elif active.type == LToken.Type.OP_NOT:
        if active._parent == null:
            return null

        if child && !_can_have_more_decendants(active):
            return null

        if child && !_add_descendant(active, child):
            return null

        return _insert_operator_in_tree(active, new_token)

    elif [LToken.Type.LITERAL_STRING, LToken.Type.LITERAL_INT, LToken.Type.LITERAL_BOOL, LToken.Type.LITERAL_FLOAT].has(active.type):
        if !char_buffer.is_empty():
            return null

        return _insert_operator_in_tree(active, new_token)

    elif active.type == LToken.Type.OP_OR || new_token.type == LToken.Type.OP_AND:
        if child == null:
            return null

        if !_add_descendant(new_token, child) || !_add_descendant(active, new_token):
            return null

        return new_token

    if char_buffer.is_empty():
        return null

    var need_shuffle: bool
    while active.type == LToken.Type.OP_AND:
        if active._descendants.size() != 1:
            return null

        if active._parent == null:
            return null

        need_shuffle = true
        active = active._parent

    if need_shuffle:
        if child == null || active._descendants.is_empty():
            return null

        if !_can_have_more_decendants(new_token):
            return null

        var last: LToken = active._descendants.pop_back()
        if last.type != LToken.Type.OP_AND && last._descendants.size() != 1:
            return null


        if !_add_descendant(last, child) || !_add_descendant(new_token, last) || !_add_descendant(active, new_token):
            return null

        return new_token

    dtype = _char_buffer_disambiguation(char_buffer)
    if dtype == LToken.Type.ERROR:
        return null

    if !_add_descendant(new_token, LToken.new(dtype, char_buffer)) || !_add_descendant(active, new_token):
        return null

    return new_token

static func _insert_operator_in_tree(active: LToken, new_token: LToken) -> LToken:
    var par: LToken = active._parent
    if par == null:
        return null

    while par.type == LToken.Type.OP_AND && new_token.type == LToken.Type.OP_OR:
        par = par._parent
        if par == null:
            return null

    var repl: LToken = par._descendants.pop_back()
    if repl != active && repl.type != LToken.Type.OP_AND:
        return null

    if _add_descendant(par, new_token) && _add_descendant(new_token, repl):
        return new_token
    return null


static func _char_buffer_disambiguation(char_buffer: String) -> LToken.Type:
    if char_buffer.is_empty():
        return LToken.Type.ERROR

    if char_buffer == "true" || char_buffer == "false":
        return LToken.Type.LITERAL_BOOL

    var all_num: RegEx = RegEx.new()
    all_num.compile("^[0-9]+$")
    if all_num.search(char_buffer) != null:
        return LToken.Type.LITERAL_INT

    var float_pattern: RegEx = RegEx.new()
    float_pattern.compile("^[0-9]*\\.[0-9]*$")
    if char_buffer != "." && float_pattern.search(char_buffer) != null:
        return LToken.Type.LITERAL_FLOAT

    if char_buffer.contains("&") || char_buffer.contains("|") || char_buffer.contains("!"):
        return LToken.Type.ERROR

    return LToken.Type.PARAMETER

static func _in_function(active: LToken) -> bool:
    while active && active.type != LToken.Type.FUNCTION:
        active = active._parent

    return active != null

static func _is_complete(t: LToken) -> bool:
    if t == null:
        return false

    var n: int = t._descendants.size()

    match t.type:
        LToken.Type.STATEMENT:
            return n < 2
        LToken.Type.ERROR:
            return !t.value.is_empty()
        LToken.Type.FUNCTION:
            return true
        LToken.Type.PARAMETER:
            return n == 0 && !t._data.is_empty()
        LToken.Type.LITERAL_STRING:
            return n == 0
        LToken.Type.LITERAL_INT:
            return n == 0 && !t._data.is_empty()
        LToken.Type.LITERAL_BOOL:
            return n == 0 && !t._data.is_empty()
        LToken.Type.LITERAL_FLOAT:
            return n == 0 && !t._data.is_empty()
        LToken.Type.OP_NOT:
            return n == 1
        LToken.Type.OP_AND:
            return n == 2
        LToken.Type.OP_OR:
            return n == 2
        LToken.Type.PARENTHESIS:
            return n == 1
        _:
            return false

static func _tree_satisfied(t: LToken) -> bool:
    if !_is_complete(t):
        return false

    for desc: LToken in t._descendants:
        if !_tree_satisfied(desc):
            return false

    return true

static func _can_have_more_decendants(t: LToken) -> bool:
    if t == null:
        return false

    var n: int = t._descendants.size()

    match t.type:
        LToken.Type.STATEMENT, LToken.Type.OP_NOT, LToken.Type.PARENTHESIS:
            return n == 0
        LToken.Type.FUNCTION:
            return true
        LToken.Type.PARAMETER, LToken.Type.LITERAL_STRING, LToken.Type.LITERAL_INT, LToken.Type.LITERAL_BOOL, LToken.Type.LITERAL_FLOAT:
            return false
        LToken.Type.OP_AND, LToken.Type.OP_OR:
            return n < 2
        _:
            return false

static func _is_valid_tree(t: LToken, visited: Array[LToken] = []) -> bool:
    if t._parent == t || visited.has(t):
        return false

    visited.append(t)

    for desc: LToken in t._descendants:
        if !_is_valid_tree(desc, visited):
            return false

    return true

static func _create_token_type_from_buffer(statement: LToken, char_buffer: String, idx: int, strip: bool = true) -> LToken:
    if strip:
        char_buffer = char_buffer.strip_edges()

    if char_buffer.is_empty():
        _error(statement, "Missing parameter or literal at %s" % idx)
        return null

    var dtype: LToken.Type = _char_buffer_disambiguation(char_buffer)
    if dtype == LToken.Type.ERROR:
        _error(statement, "Invalid parameter or literal at %s" % idx)
        return null
    return LToken.new(dtype, char_buffer)

static func _add_descendant(parent: LToken, descendant: LToken, take_descendants_place: bool = false) -> bool:
    if descendant == parent:
        push_error("%s cannot have itself as descendant" % [parent.info(true, 1)])
        return false

    var d_parent: LToken = descendant._parent
    if d_parent == parent:
        if take_descendants_place:
            return false
        return true

    if !_can_have_more_decendants(parent):
        return false

    if d_parent:
        d_parent._descendants.erase(descendant)

    descendant._parent = parent
    parent._descendants.append(descendant)

    if take_descendants_place:
        if parent._parent:
            parent._parent._descendants.erase(parent)

        d_parent._descendants.append(parent)
        parent._parent = d_parent

    return true

static func _error(statement: LToken, message: String) -> LToken:
    statement.type = LToken.Type.ERROR
    statement.value = message
    return statement

static func parse(text: String) -> LToken:
    var statement: LToken = LToken.new()

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
    var active: LToken = statement
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

                    var d: LToken = LToken.new(LToken.Type.LITERAL_STRING, char_buffer)
                    if !_add_descendant(active, d):
                        return _error(statement, "%s cannot take string literal '%s' at '%s'" % [active.info(true, 1), char_buffer, idx])

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
                        return _error(statement, "Only && and || operands supported at %s" % [idx])

                    char_buffer += " "

                ",":
                    if active.type == LToken.Type.FUNCTION:
                        var child: LToken = _create_token_type_from_buffer(statement, char_buffer, idx)
                        if child == null:
                            return _error(statement, "%s has empty parameter at %s" % [active.info(true, 1), idx])

                        if !_add_descendant(active, child):
                            return _error(statement, "Failed to add '%s' to %s at %s" % [char_buffer, active.info(true, 1), idx])

                        char_buffer = ""
                    else:
                        if char_buffer.is_empty():
                            if active.type == LToken.Type.FUNCTION:
                                return _error(statement, "Empty function parameter to %s at %s" % [active.info(true, 1), idx])
                        else:
                            var child: LToken = _create_token_type_from_buffer(statement, char_buffer, idx)
                            if child == null:
                                return _error(statement, "Missing required child to %s at %s" % [active.info(true, 1), idx])

                            if !_add_descendant(active, child):
                                return _error(statement, "Failed to add '%s' to %s at %s" % [char_buffer, active.info(true, 1), idx])

                        while active != null && active.type != LToken.Type.FUNCTION:
                            active = active._parent

                        if active == null:
                            return _error(statement, "Listing only allowed for function parameters, position %s not inside function" % [idx])

                "(":
                    char_buffer = char_buffer.strip_edges()
                    if char_buffer.is_empty():
                        if !_can_have_more_decendants(active):
                            return _error(statement, "%s cannot have a parenthesis at %s" % [LToken.Type.find_key(active.type), idx])


                        var par: LToken = LToken.new(LToken.Type.PARENTHESIS)
                        if !_add_descendant(active, par):
                            return _error(statement, "Cannot add %s to %s at %s" % [par.info(), active.info(true, 1), idx])

                        active = par
                        parenthesis_stack.append(par)

                    elif function_name.search(char_buffer) != null:
                        if !_can_have_more_decendants(active):
                            return _error(statement, "%s cannot have a function '%s' decendant at %s" % [active.info(true, 1), char_buffer, idx])

                        var fn: LToken = LToken.new(LToken.Type.FUNCTION, char_buffer)

                        if !_add_descendant(active, fn):
                            return _error(statement, "%s cannot be added to %s at %s" % [fn.info(), active.info(true, 1), idx])

                        active = fn
                        parenthesis_stack.append(fn)
                        char_buffer = ""
                    else:
                        return _error(statement, "Illegal function name '%s' at %s" % [char_buffer, idx])

                ")":
                    char_buffer = char_buffer.strip_edges()
                    if !char_buffer.is_empty():
                        if !_can_have_more_decendants(active):
                            return _error(statement, "%s cannot have '%s' decendant at %s" % [active.info(), char_buffer, idx])

                        var child: LToken = _create_token_type_from_buffer(statement, char_buffer, idx, false)
                        if child == null:
                            return

                        if !_add_descendant(active, child):
                            return _error(statement, "%s cannot be added to %s at %s" % [child.info(), active.info(true, 1), idx])

                    if parenthesis_stack.is_empty():
                        return _error(statement, "Unmatched right side parenthesis at %s" % idx)

                    var closed: LToken = parenthesis_stack.pop_back()
                    while active != closed:
                        active = active._parent
                        if active == null:
                            return _error(statement, "Failed to find %s by closing parenthesis at %s" % [closed.info(), idx])

                    if !_is_complete(active):
                        return _error(statement, "%s is incomplete at %s" % [active.info(), idx])

                    char_buffer = ""

                "!":
                    char_buffer = char_buffer.strip_edges()
                    if !char_buffer.is_empty():
                        return _error(statement, "! cannot follow '%s' at position %s" % [char_buffer, idx])

                    elif !_can_have_more_decendants(active):
                        return _error(statement, "! cannot be decendent of a %s at postion %s" % [active.info(true, 1), idx])

                    else:

                        var d: LToken = LToken.new(LToken.Type.OP_NOT)
                        if !_add_descendant(active, d):
                            return _error(statement, "Could not add %s to %s at %s" % [d.info(), active.info(true, 1), idx])

                        active = d

                "&":
                    if !char_buffer.is_empty() && char_buffer[char_buffer.length() - 1] == "&":
                        char_buffer = char_buffer.trim_suffix("&").strip_edges()

                        var d: LToken = LToken.new(LToken.Type.OP_AND)
                        active = _add_left_side(d, active, char_buffer, parenthesis_stack)
                        if active == null:
                            return _error(statement, "Not a valid left side of && at %s" % idx)

                        char_buffer = ""
                    elif char_buffer.is_empty():
                        return _error(statement, "Operator at %s requires a left side %s" % idx)
                    elif char_buffer.contains("|"):
                        return _error(statement, "Jumbled operator at %s" % idx)
                    else:
                        char_buffer += "&"

                "|":
                    if !char_buffer.is_empty() && char_buffer[char_buffer.length() - 1] == "|":
                        char_buffer = char_buffer.trim_suffix("|").strip_edges()

                        var d: LToken = LToken.new(LToken.Type.OP_OR)
                        active = _add_left_side(d, active, char_buffer, parenthesis_stack)
                        if active == null:
                            return _error(statement, "Not a valid left side of || at %s" % idx)

                        char_buffer = ""
                    elif char_buffer.is_empty():
                        return _error(statement, "Operator at %s requires a left side %s" % idx)
                    elif char_buffer.contains("|"):
                        return _error(statement, "Jumbled operator at %s" % idx)
                    else:
                        char_buffer += "|"

                "\"":
                    if in_string_litteral:
                        in_string_litteral = false
                        if !_can_have_more_decendants(active):
                            return _error(statement, "%s cannot take string '%s' at %s" % [active.info(), char_buffer, idx])

                        var d: LToken = LToken.new(LToken.Type.LITERAL_STRING, char_buffer)
                        if !_add_descendant(active, d):
                            return _error(statement, "Could not add descendant %s to %s" % [d.info(), active.info(true, 1)])
                        active = d
                        char_buffer = ""
                    else:
                        char_buffer = char_buffer.strip_edges()
                        if !char_buffer.is_empty():
                            return _error(statement, "String literal cannot follow '%s' at %s" % [char_buffer, idx])


                        in_string_litteral = true
                ".":
                    char_buffer += "."
                ":":
                    char_buffer += ":"
                _:
                    return _error(statement, "Illegal character '%s' at %s" % [text[idx], idx])

            idx += 1
            continue

    char_buffer = char_buffer.strip_edges()
    if !char_buffer.is_empty():
        if !_can_have_more_decendants(active):
            return _error(statement, "%s doesn't allow more decendants but had remaining '%s'" % [active.info(true), char_buffer])

        var child: LToken = _create_token_type_from_buffer(statement, char_buffer, idx, false)
        if child == null:
            return _error(statement, "Failed to parse token '%s' at %s" % [char_buffer, idx])

        if !_add_descendant(active, child):
            return _error(statement, "Could not add descendant %s to %s" % [child.info(), active.info(true, 1)])

    if !parenthesis_stack.is_empty():
        return _error(statement, "%s isn't closed" % parenthesis_stack[parenthesis_stack.size() - 1].info(true))

    if !_tree_satisfied(statement):
        return _error(statement, "%s is not satisfied" % active.info(true))

    if !_is_valid_tree(statement):
        return _error(statement, "%s is not a valid tree" % active.info(true, 10))

    return statement
