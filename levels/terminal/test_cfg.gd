extends Node

@export var location: GamePlace

func _ready() -> void:
    _load()

func _load() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    cfg.load("res://tesst.cfg")
    print_debug(cfg.get_value("RECEPTION", "targets"))
    print_debug(cfg.get_value("RECEPTION", "desc"))

func _save() -> void:
    var cfg: ConfigFile = ConfigFile.new()

    cfg.set_value(location.location, "desc", location._descriptions)
    cfg.set_value(location.location, "state", location.state)
    cfg.set_value(location.location, "state_desc", location.state_descriptors)
    cfg.set_value(location.location, "auto_inc", location.auto_increment_description)
    cfg.set_value(location.location, "set_global_state", location.add_global_state)


    cfg.save("res://tesst.cfg")
