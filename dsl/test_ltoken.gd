extends Node

var tests: Array[Array] = [
    ["", "[STATEMENT]"],
    ["func(43)", "[STATEMENT: [FUNCTION func: [LITERAL_INT 43]]]"],
    ["INVENTORY(LOBBY BADGE)", "[STATEMENT: [FUNCTION INVENTORY: [PARAMETER LOBBY BADGE]]]"],
    ["true", "[STATEMENT: [LITTERAL_BOOL true]]"],
    ["\"test\\\"\" && 1.2", "[STATEMENT: [OP_AND: [LITERAL_STRING: test\"], [LITERAL_FLOAT 1.2]]]"]
]
func _ready() -> void:
    var t: LToken = LToken.new()

    for test in tests:
        t.parse(test[0])
        if t.info(true) == test[1]:
            print("PASS: %s => %s" % test)
        else:
            print("FAIL: %s => %s not %s" % [test[0], t.info(true), test[1]])
