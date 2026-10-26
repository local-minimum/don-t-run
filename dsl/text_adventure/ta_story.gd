extends Node
class_name TAStory

@export var interpreter: TAInterpreter

var nodes: Array[TANode]
var active_node_stack: Array[TANode]

#region Entity
func get_entity_name(entity: TAEntity) -> String:
    interpreter.active = entity
    return String(interpreter.eval(entity.name))

func get_entity_text(entity: TAEntity, fallback_visits: bool = true) -> String:
    if entity.texts.is_empty():
        return ""

    if entity.text_rule != null:
        interpreter.active = entity
        var val: Variant = interpreter.eval(entity.text_rule)
        if val is int:
            return entity.texts[clampi(val, 0, entity.texts.size() - 1)]

    if fallback_visits:
        return entity.texts[mini(entity.visits, entity.texts.size() - 1)]

    return entity.texts[0]

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

    return ret
#endregion Node

#region Edge
func get_edge_hidden(edge: TAEdge) -> bool:
    interpreter.active = edge
    if interpreter.eval(edge.hidden):
        return true
    return false
#endregion Edge
