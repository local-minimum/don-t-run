extends TAEntity
class_name TANode

var edges: Array[TAEdge]

func add_edge(edge: TAEdge) -> void:
    if edge.node && edge.node != self:
        edge.node.edges.erase(edge)

    edge.node = self
    edges.append(edge)

func orphan_edge(edge: TAEdge) -> bool:
    if edges.has(edge):
        edges.erase(edge)
        edge.node = null
        return true
    return false

func get_edge(eid: String) -> TAEdge:
    for e: TAEdge in edges:
        if e.id == eid:
            return e

    return null

func _to_string() -> String:
    return "[%s: %s edge%s]" % [id, edges.size(), "" if edges.size() == 1 else "s"]
