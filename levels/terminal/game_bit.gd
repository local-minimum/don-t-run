extends Node
class_name GameBit

var active_description: int = 0
@export var hidden: bool = false
@export_multiline() var _descriptions: Array[String]
@export var auto_increment_description: bool

var description: String:
    get():
        if _descriptions.is_empty():
            return ""
        return _descriptions[mini(active_description, _descriptions.size() - 1)]
