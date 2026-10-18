extends GameBit
class_name GamePlace

const ACTION_LOOK = "LOOK"
const ACTION_GO = "GO"
const ACTION_USE = "USE"
const ACTION_TALK = "TALK"
const ACTION_TAKE = "TAKE"

@export var location: String
@export var state: Array[String]
@export var state_descriptors: Dictionary[String, String] = {}
var _transitions: Array[GameTransition]
var _interactions: Array[GameInteraction]

func get_extended_description(game: TerminalGame) -> String:
    var ret: String = "==%s==\n%s" % [location, description]
    for s: String in state:
        ret += state_descriptors.get(s, "")
    for s: String in game.state:
        if state_descriptors.has(s) && !state.has(s):
            ret += state_descriptors[s]
    return ret

var actions: Array[String]:
    get():
        var ret: Array[String] = []
        for t: GameTransition in _transitions:
            if t.hidden || t.blocked:
                continue

            for a: String in t.actions:
                if !ret.has(a):
                    ret.append(a)

        for i: GameInteraction in _interactions:
            if i.hidden || i.blocked:
                continue

            i.append_trigger_actions(ret)

        return ret

var added_targets: Array[String]

var targets: Array[String]:
    get():
        var ret: Array[String] = []

        for i: GameInteraction in _interactions:
            if i.hidden || i.blocked:
                continue

            i.append_trigger_targets(ret)

        for t: GameTransition in _transitions:
            if !t.hidden && !t.blocked:
                ret.append(t.target)

        for t: String in added_targets:
            if !ret.has(t):
                ret.append(t)

        return ret

func sync(_game: TerminalGame) -> void:
    pass

func get_bit(action: String, target: String) -> GameBit:
    var trigger = "%s %s" % [action, target]
    for t: GameTransition in _transitions:
        if !t.blocked && t.actions.has(action) && t.target == target && (!t.hidden || t.target == target && targets.has(target)):
            return t

    for i: GameInteraction in _interactions:
        if !i.blocked && i.triggers.has(trigger) && (!i.hidden || i.is_target(target) && targets.has(target)):
            return i

    return null

func _ready() -> void:
    _transitions.append_array(find_children("", "GameTransition"))
    _interactions.append_array(find_children("", "GameInteraction"))
