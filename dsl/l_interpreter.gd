extends Node
class_name LInterpreter

const _LITERALS: Array[LToken.Type] = [LToken.Type.LITERAL_STRING, LToken.Type.LITERAL_INT, LToken.Type.LITERAL_FLOAT, LToken.Type.LITERAL_BOOL]
const _OPS: Array[LToken.Type] = [LToken.Type.OP_NOT, LToken.Type.OP_AND, LToken.Type.OP_OR]

var _valid_functions: Array[String]

func _enter_tree() -> void:
    for m: Dictionary in get_method_list():
        if !m['name'].begins_with("_func_"):
            continue
        _valid_functions.append(m['name'].substr(6))

    print(_valid_functions)

func eval(statement: LToken, values: Dictionary[LToken, Variant]) -> Variant:
    if statement == null:
        return null

    var current: LToken = statement
    var visited: Array[LToken]
    var bail:int = 100

    while bail > 0 && !values.has(statement):
        bail -= 1

        if !visited.has(current):
            visited.append(current)

        if _try_eval(current, values):
            if current == statement:
                break
            current = current._parent
        else:
            var found_new: bool = false
            for descendant: LToken in current._descendants:
                if visited.has(descendant):
                    continue

                found_new = true
                current = descendant
                break

            if current == statement:
                break

            if !found_new:
                current = current._parent


    return values.get(statement, null)

func _get_function_parameters(token: LToken) -> Array[LToken]:
    var params: Array[LToken] = []
    if !token.type == LToken.Type.FUNCTION:
        return params

    var stack: Array[LToken] = [token]
    while !stack.is_empty():
        var current: LToken = stack.pop_back()
        for descendant: LToken in current._descendants:
            if descendant.is_parameter:
                params.append(descendant.parameter_name)
            elif descendant.type != LToken.Type.FUNCTION && !_LITERALS.has(descendant.Type):
                stack.append(descendant)

    return params


func _try_eval(token: LToken, values: Dictionary[LToken, Variant]) -> bool:
    if _LITERALS.has(token.type):
        values[token] = token.value
        return true

    if token.type == LToken.Type.PARAMETER:
        values[token] = token

    if token.type == LToken.Type.STATEMENT:
        if token._descendants.is_empty():
            values[token] = null
            return true

        elif values.has(token._descendants[0]):
            values[token] = values[token._descendants[0]]
            return true

    elif _OPS.has(token.type):
        match token.type:
            LToken.Type.OP_NOT:
                if values.has(token._descendants[0]):
                    values[token] = !values[token._descendants[0]]
                    return true

            LToken.Type.OP_AND:
                if !values.has(token._descendants[0]):
                    return false

                if !values[token._descendants[0]]:
                    values[token] = false
                    return true

                if values.has(token._descendants[1]):
                    values[token] = values[token._descendants[1]]
                    return true

            LToken.Type.OP_OR:
                if !values.has(token._descendants[0]):
                    return false

                if values[token._descendants[0]]:
                    values[token] = true
                    return true

                if values.has(token._descendants[1]):
                    values[token] = values[token._descendants[1]]
                    return true
            _:
                push_error("Operator %s not implemented" % [LToken.Type.find_key(token.type)])
                return false

        return false

    elif token.type == LToken.Type.FUNCTION:
        if !_valid_functions.has(token.function_name):
            push_error("Function %s not supported (valid functions: %s)" % [token.info(true, 1), _valid_functions])
            values[token] = null
            return true

        if token._descendants.all(func (d: LToken) -> bool: return values.has(d)):
            values[token] = callv("_func_%s" % token.function_name, token._descendants.map(func (d: LToken) -> Variant: return values.get(d, null)))
            return true

    return false

"""Picks a random index of arguments that matches the first argument"""
func _func_pick_index(value: Variant, ...args: Array) -> int:
    if args.is_empty():
        return -1

    var opts: Array[int] = []
    for idx: int in args.size():
        if args[idx] == value:
            opts.append(idx)

    return opts.pick_random()

func _func_add(a: Variant, b: Variant) -> Variant:
    return a + b
