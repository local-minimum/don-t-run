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

func eval(statement: LToken) -> Variant:
    if statement == null:
        return null

    var values: Dictionary[LToken, Variant] = {}
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


func _try_eval(token: LToken, values: Dictionary[LToken, Variant]) -> bool:
    if _LITERALS.has(token.type):
        values[token] = token.value
        return true

    if token.type == LToken.Type.STATEMENT:
        if token._descendants.is_empty():
            values[token] = null
            return true
        elif values.has(token._descendants[0]):
            values[token] = values[token._descendants[0]]
            return true

    elif _OPS.has(token.type):
        if token._descendants.all(func (d: LToken) -> bool: return values.has(d)):
            match token.type:
                LToken.Type.OP_NOT:
                    values[token] = !values[token._descendants[0]]
                LToken.Type.OP_AND:
                    values[token] = values[token._descendants[0]] && values[token._descendants[1]]
                LToken.Type.OP_OR:
                    values[token] = values[token._descendants[0]] || values[token._descendants[1]]
                _:
                    push_error("Operator %s not implemented" % [LToken.Type.find_key(token.type)])
                    return false

            return true

    elif token.type == LToken.Type.FUNCTION:
        if !_valid_functions.has(token.function_name):
            push_error("Function %s not supported (valid functions: %s)" % [token.info(true, 1), _valid_functions])
            values[token] = null
            return true

        if token._descendants.all(func (d: LToken) -> bool: return values.has(d)):
            values[token] = call("_func_%s" % token.function_name, token._descendants.map(func (d: LToken) -> Variant: return values.get(d, null)))
            return true

    return false

func _func_pick_true_index(args: Array) -> int:
    if args.is_empty():
        return -1

    var opts: Array[int] = []
    for idx: int in args.size():
        if args[idx]:
            opts.append(idx)

    return opts.pick_random()

func _func_add(args: Array) -> Variant:
    if args.is_empty():
        return null

    var sum: Variant
    match typeof(args[0]):
        TYPE_BOOL:
            sum = false
        TYPE_INT:
            sum = 0
        TYPE_FLOAT:
            sum = 0.0
        TYPE_STRING:
            sum = ""
        _:
            sum = null

    for val: Variant in args:
        sum += val
    return sum
