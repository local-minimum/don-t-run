extends TAEntity
class_name TAEdge

var node: TANode

var commands: Array[TACommand]

var command_actions: Array[String]:
    get():
        var ret: Array[String]
        for command: TACommand in commands:
            if !command.catch_all_action:
                ret.append(command._action)
        return ret

var command_referents: Array[String]:
    get():
        var ret: Array[String]
        for command: TACommand in commands:
            if !command.catch_all_referent:
                ret.append(command._referent)
        return ret

var hidden: LToken
var target: LToken
