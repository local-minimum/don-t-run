extends Node
class_name TAStory

signal executed(entity: TAEntity, text: String, title: String)
signal story_loaded()

@export var interpreter: TAInterpreter
@export_file("*.cfg") var story_file: String
@export var start_id: String
@export var autoload: bool = true
@export var node_title_decoration: String = "== %s =="

var _edges: Dictionary[String, TAEdge] = {}
var nodes: Array[TANode]
var active_node_stack: Array[TANode]
var globals: Array[TAEntity]

const _VERBOSE: bool = false

func _ready() -> void:
    if autoload:
        if !load_story():
            push_error("Failed to load story %s" % story_file)
        print(self)

func set_backtrack_active_node() -> bool:
    if active_node_stack.size() < 2:
        return false
    active_node_stack.pop_back()
    return true

func get_first_nonglobal_active_node() -> TANode:
    var i: int = active_node_stack.size() - 1
    while i >= 0:
        var n: TANode = active_node_stack[i]
        if !globals.has(n):
            return n
    return null

func set_active_node(node: TANode, pop_current: bool = true) -> void:
    if !active_node_stack.is_empty() && active_node_stack[-1] == node:
        return

    if pop_current:
        active_node_stack.pop_back()

    active_node_stack.append(node)

func get_active_node(include_global: bool = true) -> TANode:
    if active_node_stack.is_empty():
        return null

    if include_global:
        return active_node_stack[-1]

    for idx in range(active_node_stack.size() - 1, -1, -1):
        if !globals.has(active_node_stack[idx]):
            return active_node_stack[idx]

    return null

func find_edge(id: String) -> TAEdge:
    return _edges.get(id)

func find_node(id: String) -> TANode:
    for n: TANode in nodes:
        if n.id == id:
            return n

    for e: TAEntity in globals:
        if e is TANode && e.id == id:
            return e

    return null

func _to_string() -> String:
    return "{%s %s node%s, active: %s}" % [story_file.split("/")[-1], nodes.size(), "" if nodes.size() == 1 else "s", active_node_stack]

#region Loading
func load_story() -> bool:
    nodes.clear()
    active_node_stack.clear()
    var cfg: ConfigFile = ConfigFile.new()
    cfg.load(story_file)

    for section in cfg.get_sections():
        if _VERBOSE:
            print("\n== %s ==" % [section])

        var t: Variant = cfg.get_value(section, "type", "")
        if t == "node":
            pass
        elif section.contains(":") || t == "edge":
            continue
        var global: bool = cfg.get_value(section, "global", false)

        var node: TANode = TANode.new(section)
        if global:
            globals.append(node)
        else:
            nodes.append(node)

        if start_id == section:
            active_node_stack.append(node)

        for key in cfg.get_section_keys(section):
            if _add_common_key(node, cfg, section, key):
                continue

            push_error("%s of %s is not a valid setting" % [key, section])

    for section in cfg.get_sections():
        var global: bool = cfg.get_value(section, "global", false)
        var t: Variant = cfg.get_value(section, "type", "")
        if t == "node" || t != "edge" && !section.contains(":"):
            continue

        var edge: TAEdge = TAEdge.new(section)

        if _VERBOSE:
            print("\n== %s ==" % [section])

        for key in cfg.get_section_keys(section):
            if _add_common_key(edge, cfg, section, key):
                continue

            match key:
                "command", "commands":
                    var val: Variant = cfg.get_value(section, key)
                    if val is Array:
                        var arr: Array = val as Array
                        if arr.all(
                            func (cmd: Variant) -> bool:
                                return cmd is Array && (cmd as Array).all(func (e: Variant) -> bool: return e is String)
                        ):
                            edge.commands.append_array(arr.map(func (cmd: Array) -> TACommand: return TACommand.new(cmd)))
                            if _VERBOSE:
                                print("COMMANDS: %s" % [val])
                        elif arr.size() == 2 && arr.all(func(s: Variant) -> bool: return s is String):
                            edge.commands.append(TACommand.new(arr))
                            if _VERBOSE:
                                print("COMMANDS: %s" % [val])
                        else:
                            push_error("Failed to parse '%s' of '%s'. All commands must be string arrays: %s" % [key, section, val])
                    else:
                        push_error("Failed to parse '%s' of '%s', must be an array of arrays of strings: %s" % [key, section, val])

                "hidden":
                    var val: LToken = LDSL_Parser.parse(cfg.get_value(section, key))
                    if val.is_error:
                        push_error("Failed to parse '%s' of '%s': %s" % [section, key, val.info()])
                    elif !interpreter.validate(val):
                        push_error("Invalid %s for %s: %s" % [key, section, val])
                    else:
                        edge.hidden = val
                        if _VERBOSE:
                            print("%s => %s" % [cfg.get_value(section, key), val])

                "target":
                    var val: LToken = LDSL_Parser.parse(cfg.get_value(section, key))
                    if val.is_error:
                        push_error("Failed to parse '%s' of '%s': %s" % [section, key, val.info()])
                    elif !interpreter.validate(val):
                        push_error("Invalid %s for %s: %s" % [key, section, val])
                    else:
                        edge.target = val
                        if _VERBOSE:
                            print("%s => %s" % [cfg.get_value(section, key), val])
                _:
                    push_error("'%s' of '%s' not a valid setting" % [key, section])

        _edges[edge.id] = edge

        if global:
            globals.append(edge)
            continue

        var found: bool = false
        var node_id: String = section.split(":")[0]
        for node: TANode in nodes:
            if node.id == node_id:
                found = true
                node.add_edge(edge)
                break

        if !found:
            for entity: TAEntity in globals:
                if entity is TANode && entity.id == node_id:
                    found = true
                    (entity as TANode).add_edge(edge)
                    break

        if !found:
            push_error("Edge '%s' with id '%s' cannot find a node with id '%s'" % [section, edge.id, node_id])

    story_loaded.emit()
    return !nodes.is_empty() && !active_node_stack.is_empty()

func _add_common_key(entity: TAEntity, cfg: ConfigFile, section: String, key: String) -> bool:
    match key:
        "type", "global":
            # This overrides default node vs edge assignment and should not be assigned to the node/edge
            pass

        "id":
            var val: Variant = cfg.get_value(section, key)
            if val is String:
                entity.id = val
            else:
                push_error("'%s' of '%s' must be a string" % [key, section])

        "name":
            var val: LToken = LDSL_Parser.parse(cfg.get_value(section, key))
            if val.is_error:
                push_error("Failed parsing '%s' of '%s': %s" % [key, section, val.info()])
            elif !interpreter.validate(val):
                push_error("Invalid %s for %s: %s" % [key, section, val])
            else:
                entity.name = val
                if _VERBOSE:
                    print("%s => %s" % [cfg.get_value(section, key), val])

        "text_rule":
            var val: LToken = LDSL_Parser.parse(cfg.get_value(section, key))
            if val.is_error:
                push_error("Failed parsing '%s' of '%s': %s" % [key, section, val.info()])
            elif !interpreter.validate(val):
                push_error("Invalid %s for %s: %s" % [key, section, val])
            else:
                entity.text_rule = val
                if _VERBOSE:
                    print("%s => %s" % [cfg.get_value(section, key), val])

        "text", "texts":
            var val: Variant = cfg.get_value(section, key)
            if val is String:
                entity.texts.append(val)
            elif val is Array:
                entity.texts.append_array(val)
            else:
                push_error("'%s' of '%s' is not string or array of strings" % [key, section])

        "effect":
            var val: LToken = LDSL_Parser.parse(cfg.get_value(section, key))
            if val.is_error:
                push_error("Failed parsing '%s' of '%s': %s" % [key, section, val.info()])
            elif !interpreter.validate(val):
                push_error("Invalid %s for %s: %s" % [key, section, val])
            else:
                entity.effect = val
                if _VERBOSE:
                    print("%s => %s" % [cfg.get_value(section, key), val])

        _:
            return false

    return true
#endregion Loading

#region Entity
func get_entity_name(entity: TAEntity) -> String:
    interpreter.active = entity
    var n: Variant = interpreter.eval(entity.name)
    if n is LToken && (n as LToken).is_parameter:
        return (n as LToken).parameter_name

    return String(interpreter.eval(entity.name))

func get_entity_text(entity: TAEntity, fallback_visits: bool = true) -> String:
    var resolved_text: bool = false
    var etext: String = ""
    if !entity.texts.is_empty():
        if entity.text_rule != null:
            interpreter.active = entity
            var val: Variant = interpreter.eval(entity.text_rule)
            if val is int:
                etext = entity.texts[clampi(val, 0, entity.texts.size() - 1)]
                resolved_text = true

        if !resolved_text && fallback_visits:
            etext = entity.texts[mini(entity.visits, entity.texts.size() - 1)]

        if !resolved_text:
            etext = entity.texts[0]

    var appended: String = entity.get_appended_text()
    if !appended.is_empty():
        return etext + appended
    return etext

func execute_entity_effect(entity: TAEntity) -> void:
    if entity.effect == null:
        return

    interpreter.active = entity
    interpreter.eval(entity.effect)
#endregion Entity

#region Node
func get_actions(node: TANode, defaults: Array[String] = []) -> Array[String]:
    var ret: Array[String] = []
    if !defaults.is_empty():
        ret.append_array(defaults)

    for edge: TAEdge in node.edges:
        if get_edge_hidden(edge):
            continue

        for action: String in edge.command_actions:
            if !ret.has(action):
                ret.append(action)

    for entity: TAEntity in globals:
        if entity is TAEdge:
            if get_edge_hidden(entity):
                continue

            for action: String in (entity as TAEdge).command_actions:
                if !ret.has(action):
                    ret.append(action)

    return ret

func get_referents(node: TANode, defaults: Array[String] = []) -> Array[String]:
    var ret: Array[String] = []
    if !defaults.is_empty():
        ret.append_array(defaults)

    for edge: TAEdge in node.edges:
        if get_edge_hidden(edge):
            continue

        for referent: String in edge.command_referents:
            if !ret.has(referent):
                ret.append(referent)

    for entity: TAEntity in globals:
        if entity is TAEdge:
            if get_edge_hidden(entity):
                continue

            for referent: String in (entity as TAEdge).command_referents:
                if !ret.has(referent):
                    ret.append(referent)

    return ret

func get_edge_by_command(node: TANode, action: String, referent: String) -> TAEdge:
    for edge: TAEdge in node.edges:
        if !get_edge_hidden(edge) && edge.matches_command(action, referent, true):
            return edge

    for edge: TAEdge in node.edges:
        if !get_edge_hidden(edge) && edge.matches_command(action, referent, false):
            return edge

    for entity: TAEntity in globals:
        if entity is TAEdge && !get_edge_hidden(entity) && (entity as TAEdge).matches_command(action, referent, true):
            return entity

    for entity: TAEntity in globals:
        if entity is TAEdge && !get_edge_hidden(entity) && (entity as TAEdge).matches_command(action, referent, false):
            return entity

    return null

func exec_active_node() -> void:
    var node: TANode = get_active_node()
    if node == null:
        push_error("No active node! Cannot execute")
        return

    interpreter.active = node
    if node.effect:
        interpreter.eval(node.effect)

    var title: String = get_entity_name(node)

    title = (node_title_decoration % title) if !node_title_decoration.is_empty() else title
    var body: String = get_entity_text(node)

    node.visits += 1

    executed.emit(node, body, title)
#endregion Node

#region Edge
func get_edge_hidden(edge: TAEdge) -> bool:
    interpreter.active = edge
    if interpreter.eval(edge.hidden):
        return true
    return false

func execute_edge_target(edge: TAEdge) -> void:
    if edge.target == null:
        return

    interpreter.active = edge
    interpreter.eval(edge.target)

func execute_edge_by_command(action: String, referant: String) -> bool:
    var node: TANode = get_active_node()
    if node == null:
        return false

    var edge = get_edge_by_command(node, action, referant)
    if edge == null:
        return false

    interpreter.active = edge
    if edge.effect:
        interpreter.eval(edge.effect)

    var body = get_entity_text(edge)

    executed.emit(edge, body, "")
    return true

#endregion Edge
