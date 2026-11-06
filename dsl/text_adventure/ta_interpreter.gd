extends LInterpreter
class_name TAInterpreter

@export var story: TAStory
var active: TAEntity

#region globals
func _get_global(id: Variant) -> TAEntity:
    if id is not String && (id is not LToken || !(id as LToken).is_parameter):
        return null

    var sid: String = id if id is String else (id as LToken).parameter_name

    for global: TAEntity in story.globals:
        if global.id == sid:
            return global

    return null

func _func_global(_fun: LToken, id: Variant, thing: Variant) -> bool:
    var global: TAEntity = _get_global(id)
    if global == null:
        return false

    if thing is not LToken:
        if thing is bool:
            return thing
        return false

    var values: Dictionary[LToken, Variant] = {}
    for param: LToken in _get_function_parameters(thing):
        var has_param: bool = global.state.has(param.parameter_name)
        if !has_param && global is TANode:
            has_param = (global as TANode).get_edge(param.parameter_name) != null
        values[param] = has_param


    return eval(thing, values)

func _func_add_global(fun: LToken, id: Variant, ...args: Array) -> bool:
    var global: TAEntity = _get_global(id)
    if global == null:
        push_error("Global %s not know, ignoring %s" % [id, fun.info(true, 1)])
        return false

    for arg: LToken in args:
        if arg.is_parameter:
            var edge: TAEdge = story.find_edge(arg.parameter_name)
            if edge:
                if global is TANode:
                    (global as TANode).add_edge(edge)
                else:
                    push_error("Failed to add edge %s to %s because not a node in %s" % [edge, global, arg.info()])
                    return false
            else:
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
            if global is TANode:
                var node: TANode = global
                var edge: TAEdge = node.get_edge(arg.parameter_name)
                var target: TANode = story.get_first_nonglobal_active_node()
                if edge != null && target != null:
                    target.add_edge(edge)
                else:
                    push_warning("There's no place to drop %s so it gets orphanned by %s from %s" % [edge, fun.info(true, 1), node])
                    node.orphan_edge(edge)

            global.state.erase(arg.parameter_name)

        else:
            push_error("Cannot remove from global %s; %s's argument %s not parameter" % [global.id, fun.info(true, 1), arg.info(),])
            return false

    return !args.is_empty()
#endregion globals

#region location
func _func_location(_fun: LToken, thing: Variant) -> bool:
    if thing is not LToken:
        if thing is bool:
            return thing
        return false

    var node: TANode = active if active is TANode else (active as TAEdge).node
    if node == null:
        return false

    var values: Dictionary[LToken, Variant] = {}
    for param: LToken in _get_function_parameters(thing):
        var has_param: bool = node.state.has(param.parameter_name)
        if !has_param:
            has_param = node.get_edge(param.parameter_name) != null
        values[param] = has_param

    return eval(thing, values)

func _func_add_location(fun: LToken, ...args: Array) -> bool:
    var node: TANode = active if active is TANode else (active as TAEdge).node
    if node == null:
        return false

    for arg: LToken in args:
        if arg.is_parameter:
            var edge: TAEdge = story.find_edge(arg.parameter_name)
            if edge:
                node.add_edge(edge)
            else:
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
            var edge: TAEdge = node.get_edge(arg.parameter_name)
            if edge != null:
                if node.orphan_edge(edge):
                    push_warning("Edge %s orphaned by %s from %s" % [edge, fun.info(true, 1), node])

            node.state.erase(arg.parameter_name)
        else:
            push_error("Cannot remove from location %s; %s's argument %s not parameter" % [node.id, fun.info(true, 1), arg.info(),])
            return false

    return !args.is_empty()

func _func_rewrite_location_referants(fun: LToken, old: Variant, new: Variant) -> bool:
    var node: TANode = active if active is TANode else null
    if active is TAEdge:
        node = (active as TAEdge).node

    if node == null:
        push_error("No active node so skipping %s" % [fun.info(true, 1)])
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
    for edge: TAEdge in node.edges:
        found = __rewrite(edge, old, new) || found

    return found

func _func_rewrite_other_location_referants(fun: LToken, id: Variant, old: Variant, new: Variant) -> bool:
    if id is String:
        pass
    elif id is LToken && (id as LToken).is_parameter:
        id = (id as LToken).parameter_name
    else:
        push_error("The id must either be a string or parameter, got %s for %s" % [id, fun.info(true, 1)])
        return false

    var node: TANode = story.find_node(id)

    if node == null:
        push_error("No node found for '%s' so skipping %s" % [id, fun.info(true, 1)])
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
    for edge: TAEdge in node.edges:
        found = __rewrite(edge, old, new) || found

    return found

func _func_active_location(_fun: LToken, loc: LToken, inc_global: Variant = true) -> bool:
    if inc_global is LToken:
        inc_global = eval(inc_global)

    var values: Dictionary[LToken, Variant] = {}
    var a: TANode = story.get_active_node(inc_global)
    for param: LToken in _get_function_parameters(loc):
        values[param] = a && a.id == param.parameter_name

    if values.is_empty():
        return false

    return eval(loc, values)

#endregion location

func _func_move(_fun: LToken, target: LToken) -> bool:
    if !target.is_parameter:
        return false

    var node: TANode = story.find_node(target.parameter_name)
    if node:
        story.set_active_node(node, !story.globals.has(node))
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
        var parts: PackedStringArray = param.parameter_name.split(":")
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

    return __rewrite(edge, old, new)

func _func_text_append(fun: LToken, value: String) -> bool:
    if !active:
        push_error("%s cannot be executed since no active entity" % [fun.info(true, 1)])
        return false

    active.set_appended_text(value)
    return true

func __rewrite(edge: TAEdge, old: String, new: String) -> bool:
    var found: bool = false
    for command: TACommand in edge.commands:
        if command._referent == old:
            found = true
            edge.state[command] = command.replace_referent(new)

    return found
