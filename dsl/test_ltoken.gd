extends Node

var tests: Array[Array] = [
    ["", "[STATEMENT]"],
    ["func(43)", "[STATEMENT: [FUNCTION func: [LITERAL_INT 43]]]"],
    ["INVENTORY(LOBBY BADGE)", "[STATEMENT: [FUNCTION INVENTORY: [PARAMETER LOBBY BADGE]]]"],
    ["true", "[STATEMENT: [LITERAL_BOOL true]]"],
    ["\"test\\\"\" && 1.2", "[STATEMENT: [OP_AND: [LITERAL_STRING test\"], [LITERAL_FLOAT 1.2]]]"],
    ["1 && 2", "[STATEMENT: [OP_AND: [LITERAL_INT 1], [LITERAL_INT 2]]]"],
    ["func(a) || func2(b)", "[STATEMENT: [OP_OR: [FUNCTION func: [PARAMETER a]], [FUNCTION func2: [PARAMETER b]]]]"],
    ["a && b && c", "[STATEMENT: [OP_AND: [PARAMETER a], [OP_AND: [PARAMETER b], [PARAMETER c]]]]"],
    ["a && b || c", "[STATEMENT: [OP_OR: [OP_AND: [PARAMETER a], [PARAMETER b]], [PARAMETER c]]]"],
    ["a || b && c", "[STATEMENT: [OP_OR: [PARAMETER a], [OP_AND: [PARAMETER b], [PARAMETER c]]]]"],
    ["func(a, b || !c && d)", "[STATEMENT: [FUNCTION func: [PARAMETER a], [OP_OR: [PARAMETER b], [OP_AND: [OP_NOT: [PARAMETER c]], [PARAMETER d]]]]]"],
]

func _ready() -> void:
    var t: LToken = LToken.new()

    for test in tests:
        t.parse(test[0])
        if t.info(true) == test[1]:
            print("PASS: %s => %s" % test)
        else:
            #t.parse(test[0])
            print("FAIL: %s => %s not %s" % [test[0], t.info(true), test[1]])
