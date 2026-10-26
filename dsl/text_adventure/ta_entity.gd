extends RefCounted
class_name TAEntity

var id: String:
    set(value):
        id = value
        if name == null:
            name = LToken.new(LToken.Type.LITERAL_STRING, value.split(":")[-1])

var name: LToken

var visits: int

var text_rule: LToken
var texts: Array[String]

var effect: LToken
