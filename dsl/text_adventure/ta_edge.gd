extends TAEntity
class_name TAEdge

var node: TANode

var commands: Array[TACommand]

var command_actions: Array[String]:
    get():
        var ret: Array[String]
        for command: TACommand in commands:
            command = state.get(command, command)
            if !command.catch_all_action:
                ret.append(command._action)
        return ret

var command_referents: Array[String]:
    get():
        var ret: Array[String]
        for command: TACommand in commands:
            command = state.get(command, command)
            if !command.catch_all_referent:
                ret.append(command._referent)
        return ret

var hidden: LToken
var target: LToken

func matches_command(action: String, referent: String, specific: bool) -> bool:
    for command: TACommand in commands:
        if command.is_specific == specific && command.matches(action, referent):
            return true
    return false

func _to_string() -> String:
    return "<%s>" % [id]
