extends TAEntity
class_name TANode

var edges: Array[TAEntity]

func add_edge(edge: TAEdge) -> void:
    if edge.node && edge.node != self:
        edge.node.edges.erase(edge)

    edge.node = self
    edges.append(edge)
