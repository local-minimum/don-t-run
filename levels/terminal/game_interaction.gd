extends GameBit
class_name GameInteraction

@export var triggers: Array[String]
@export var add_targets: Array[String]
@export var pickup: Array[GameBit]
@export var autohide: bool

func append_trigger_actions(ret: Array[String]) -> void:
    for t: String in triggers:
        var space: int = t.find(" ")
        if space > 0:
            var a: String = t.substr(0, space)
            if !ret.has(a):
                ret.append(a)

func append_trigger_targets(ret: Array[String]) -> void:
    for t: String in triggers:
        var space: int = t.find(" ")
        if space > 0:
            var a: String = t.substr(space + 1)
            if !ret.has(a):
                ret.append(a)
