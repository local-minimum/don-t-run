extends GameBit
class_name GameInteraction

@export var triggers: Array[String]
@export var add_targets: Array[String]
@export var pickup: Array[GameInteraction]
@export var autohide: bool
@export var autoblock: bool

func is_target(target: String) -> bool:
    for t: String in triggers:
        if t.ends_with(" %s" % target):
            return true
    return false

func append_trigger_actions(ret: Array[String]) -> void:
    if blocked:
        return

    for t: String in triggers:
        var space: int = t.find(" ")
        if space > 0:
            var a: String = t.substr(0, space)
            if !ret.has(a):
                ret.append(a)

func append_trigger_targets(ret: Array[String]) -> void:
    if blocked:
        return

    for t: String in triggers:
        var space: int = t.find(" ")
        if space > 0:
            var a: String = t.substr(space + 1)
            if !ret.has(a):
                ret.append(a)
