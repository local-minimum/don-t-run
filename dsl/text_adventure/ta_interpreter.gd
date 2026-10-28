extends LInterpreter
class_name TAInterpreter

@export var story: TAStory
var active: TAEntity

#region globals
func _get_global(id: Variant) -> TAEntity:
    if id is not String && (id is not LToken || (id as LToken).is_parameter):
        return null

    var sid: String = id if id is String else (id as LToken).parameter_name

    for global: TAEntity in story.globals:
        if global.id == sid:
            return global

    return null

func _func_global(_fun: LToken, id: Variant, thing: LToken) -> bool:
    var global: TAEntity = _get_global(id)
    if global == null:
        return false

    var values: Dictionary[LToken, Variant] = {}
    for param: LToken in _get_function_parameters(thing):
        values[param] = global.state.has(thing.parameter_name)

    return eval(thing, values)

func _func_add_global(fun: LToken, id: Variant, ...args: Array) -> bool:
    var global: TAEntity = _get_global(id)
    if global == null:
        return false

    for arg: LToken in args:
        if arg.is_parameter:
           global.state[arg.parameter_name] = true
        else:
            push_error("Cannot add to global %s; %s's argument %s not parameter" % [global.id, fun.info(true, 1), arg.info(),])
            return false

    return !args.is_empty()

func _func_remove_global(fun: LToken, id: Variant, ...args: Array) -> bool:
    var global: TAEntity = _get_global(id)
    if global == null:
        return false

    for arg: LToken in args:
        if arg.is_parameter:
            global.state.erase(arg.parameter_name)
        else:
            push_error("Cannot remove from global %s; %s's argument %s not parameter" % [global.id, fun.info(true, 1), arg.info(),])
            return false

    return !args.is_empty()
#endregion globals

#region location
func _func_location(_fun: LToken, thing: LToken) -> bool:
    var node: TANode = active if active is TANode else (active as TAEdge).node
    if node == null:
        return false

    var values: Dictionary[LToken, Variant] = {}
    for param: LToken in _get_function_parameters(thing):
        values[param] = node.state.has(thing.parameter_name)

    return eval(thing, values)

func _func_add_location(fun: LToken, ...args: Array) -> bool:
    var node: TANode = active if active is TANode else (active as TAEdge).node
    if node == null:
        return false

    for arg: LToken in args:
        if arg.is_parameter:
           node.state[arg.parameter_name] = true
        else:
            push_error("Cannot add to location  %s; %s's argument %s not parameter" % [node.id, fun.info(true, 1), arg.info(),])
            return false

    return !args.is_empty()

func _func_remove_location(fun: LToken, ...args: Array) -> bool:
    var node: TANode = active if active is TANode else (active as TAEdge).node
    if node == null:
        return false

    for arg: LToken in args:
        if arg.is_parameter:
            node.state.erase(arg.parameter_name)
        else:
            push_error("Cannot remove from location %s; %s's argument %s not parameter" % [node.id, fun.info(true, 1), arg.info(),])
            return false

    return !args.is_empty()
#endregion location

func _func_move(_fun: LToken, target: LToken, pop_current: bool = true) -> bool:
    if !target.is_parameter:
        return false

    for node: TANode in story.nodes:
        if node.id == target.parameter_name:
            story.set_active_node(node, pop_current)
            return true

    return false

func _func_move_back(_fun: LToken) -> bool:
    return story.set_backtrack_active_node()

func _func_param(fun: LToken, target: LToken) -> Variant:
    if active == null:
        push_error("No active node trying to process %s" % [fun.info(true, 1)])
        return null

    var values: Dictionary[LToken, Variant] = {}
    for param: LToken in _get_function_parameters(target):
        var parts: PackedStringArray = target.parameter_name.split(":")
        var secondary: String = parts[1].strip_edges() if parts.size() > 1 else ""

        match parts[0].strip_edges():
            "visits":
                values[param] = active.visits

            "id":
                if secondary:
                    match secondary:
                        "length":
                            values[param] = active.id.length()
                        _:
                            push_error("%s cannot process '%s'" % [fun.info(true, 1), target.parameter_name])
                            return null
                else:
                    values[param] = active.id

            "texts":
                if secondary:
                    match secondary:
                        "size":
                            values[param] = active.texts.size()
                        _:
                            push_error("%s cannot process '%s'" % [fun.info(true, 1), target.parameter_name])
                            return null
                else:
                    values[param] = active.texts

            "edges":
                var node: TANode = active if active is TANode else (active as TAEdge).node
                if node == null:
                    push_error("Lacking node for %s: '%s'" % [fun.info(true, 1), param.parameter_name])
                    return null

                if secondary:
                    match secondary:
                        "size":
                            values[param] = node.edges.size()
                        _:
                            push_error("%s cannot process '%s'" % [fun.info(true, 1), target.parameter_name])
                            return null
                else:
                    values[param] = node.edges

            "command_actions":
                var edge: TAEdge = active if active is TAEdge else null
                if edge == null:
                    push_error("Active is not edge for %s: '%s'" % [fun.info(true, 1), param.parameter_name])
                    return null

                if secondary:
                    match secondary:
                        "size":
                            values[param] = edge.command_actions.size()
                        _:
                            push_error("%s cannot process '%s'" % [fun.info(true, 1), target.parameter_name])
                            return null
                else:
                    values[param] = edge.command_actions

            "command_referents":
                var edge: TAEdge = active if active is TAEdge else null
                if edge == null:
                    push_error("Active is not edge for %s: '%s'" % [fun.info(true, 1), param.parameter_name])
                    return null

                if secondary:
                    match secondary:
                        "size":
                            values[param] = edge.command_referents.size()
                        _:
                            push_error("%s cannot process '%s'" % [fun.info(true, 1), target.parameter_name])
                            return null
                else:
                    values[param] = edge.command_referents

    return eval(target, values)

func _func_rewrite_referant(fun: LToken, old: Variant, new: Variant) -> bool:
    var edge: TAEdge = active if active is TAEdge else null
    if edge == null:
        push_error("Can only rewrite rereferant on edges, active is %s so skipping %s" % [active, fun.info(true, 1)])
        return false

    if old is String:
        pass
    elif old is LToken && (old as LToken).is_parameter:
        old = (old as LToken).parameter_name
    else:
        push_error("The replaced referent must either be a string or parameter, got %s for %s" % [old, fun.info(true, 1)])
        return false

    if new is String:
        pass
    elif new is LToken && (new as LToken).is_parameter:
        new = (new as LToken).parameter_name
    else:
        push_error("The replacing referent must either be a string or parameter, got %s for %s" % [new, fun.info(true, 1)])

    var found: bool = false
    for command: TACommand in edge.commands:
        if command._referent == old:
            found = true
            edge.state[command] = command.replace_referent(new)

    return found
