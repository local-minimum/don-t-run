extends RichTextLabel
class_name OptionsPresenter

signal select_option(selected: String)
signal abort_option()

@export var selected_color = "grey"
@export var selected_bgcolor = "blue"

var options: Array[String]:
    set(value):
        options = value
        if !options.has(selected):
            if options.is_empty():
                selected = ""
            else:
                selected = options[0]

        _update_render()

var selected: String:
    set(value):
        if value.is_empty() && !options.is_empty():
            selected = options[0]
        else:
            selected = value
        _update_render()

var active: bool:
    set(value):
        active = value
        set_process_input(value)

func _update_render():
    var t: String = ""
    for opt: String in options:
        if !t.is_empty():
            t += " "

        if opt == selected:
            t += "[color=%s][bgcolor=%s]%s[/bgcolor][/color]" % [selected_color, selected_bgcolor, opt]
        else:
            t += opt

    text = t

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("select_option"):
        select_option.emit(selected)
        return

    if event.is_action_pressed("abort_option"):
        abort_option.emit()
        return


    if options.is_empty():
        return

    if event.is_action_pressed("next_option"):
        var idx: int = options.find(selected)
        if idx < 0:
            selected = options[0]
        else:
            selected = options[posmod(idx + 1, options.size())]
    elif event.is_action_pressed("prev_option"):
        var idx: int = options.find(selected)
        if idx < 0:
            selected = options[options.size() - 1]
        else:
            selected = options[posmod(idx - 1, options.size())]
