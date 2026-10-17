extends GameBit
class_name GamePlace

const ACTION_LOOK = "LOOK"
const ACTION_GO = "GO"
const ACTION_USE = "USE"
const ACTION_TALK = "TALK"
const ACTION_TAKE = "TAKE"

@export var location: String

var _transitions: Array[GameTransition]
var _interactions: Array[GameInteraction]

var actions: Array[String]:
    get():
        var ret: Array[String] = []
        for t: GameTransition in _transitions:
            if t.hidden:
                continue

            for a: String in t.actions:
                if !ret.has(a):
                    ret.append(a)

        for i: GameInteraction in _interactions:
            if i.hidden:
                continue

            i.append_trigger_actions(ret)

        return ret

var added_targets: Array[String]

var targets: Array[String]:
    get():
        var ret: Array[String] = []

        for i: GameInteraction in _interactions:
            if i.hidden:
                continue

            i.append_trigger_targets(ret)

        for t: GameTransition in _transitions:
            if !t.hidden:
                ret.append(t.target)

        for t: String in added_targets:
            if !ret.has(t):
                ret.append(t)

        return ret

func get_bit(action: String, target: String) -> GameBit:
    var trigger = "%s %s" % [action, target]
    for t: GameTransition in _transitions:
        if t.actions.has(action) && t.target == target:
            return t

    for i: GameInteraction in _interactions:
        if i.triggers.has(trigger):
            return i

    return null

func _ready() -> void:
    _transitions.append_array(find_children("", "GameTransition"))
    _interactions.append_array(find_children("", "GameInteraction"))
