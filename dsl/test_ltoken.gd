extends Node

@export var interpreter: LInterpreter

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

var tests2: Array[Array] = [
    ["", null],
    ["1", 1],
    ["2.0", 2.0],
    ["true", true],
    ["false", false],
    ["\"hello\"", "hello"],
    ["true && false", false],
    ["!false", true],
    ["1 && 2", 2],
    ["add(1, 2)", 3],
    ["false || 1 && 2", 2],
    ["pick_index(0, 2, 1, 0, 2, 51)", 2],
]

func _ready() -> void:
    for test in tests:
        var t: LToken = LDSL_Parser.parse(test[0])
        if t.info(true) == test[1]:
            print("PASS: %s => %s" % test)
        else:
            print("FAIL: %s => %s not %s" % [test[0], t.info(true), test[1]])

    print('---')

    for test in tests2:
        var t: LToken = LDSL_Parser.parse(test[0])
        if t.is_error:
            print("FAIL: Parsing error %s for '%s'" % [t.info(), test[0]])
        else:
            var val: Variant = interpreter.eval(t)
            if val == test[1]:
                print("PASS: %s => %s" % [test[0], val])
            else:
                print("FAIL: %s => %s (not %s)" % [test[0], val, test[1]])

func _func_test() -> void:
    print("TEST")
