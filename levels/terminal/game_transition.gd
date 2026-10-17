extends GameBit
class_name GameTransition

@export var actions: Array[String] = ["GO"]
@export var target: String:
    get():
        if target.is_empty():
            return place.location
        return target

@export var place: GamePlace
